"""
PySpark incremental ETL (Extract, Transform, Load) for Meta DWH.

Usage:
    spark-submit transformations/etl_pyspark.py --target-date 2026-09-15
"""

import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import (
    ArrayType,
    LongType,
    StringType,
    StructField,
    StructType,
)

INPUTS_SCHEMA = ArrayType(
    StructType([
        StructField("catalogName", StringType(), True),
        StructField("schemaName", StringType(), True),
        StructField("tableName", StringType(), True),
        StructField("physicalInputBytes", LongType(), True),
        StructField("physicalInputRows", LongType(), True),
    ])
)


def bronze_to_silver_queries(spark: SparkSession, target_date: str):
    """
    Corresponds to: transformations/bronze_to_silver_queries.sql
    """
    raw_df = spark.table("bronze.trino_query_events").filter(F.col("event_date") == target_date)
    uth_df = spark.table("silver.dim_user_team_history")

    fact_queries = (
        raw_df.alias("events")
        .join(
            uth_df.alias("user_history"),
            (F.col("events.user_name") == F.col("user_history.user_name"))
            & (F.to_date(F.col("events.created_at")) >= F.col("user_history.valid_from"))
            & (F.to_date(F.col("events.created_at")) < F.col("user_history.valid_to")),
            "left",
        )
        .select(
            F.col("events.query_id"),
            F.col("events.user_name"),
            F.coalesce(F.col("user_history.team_id"), F.lit("unassigned")).alias("team_id"),
            F.col("events.source"),
            F.col("events.query_state"),
            F.col("events.created_at"),
            F.col("events.wall_time_ms"),
            F.col("events.cpu_time_ms"),
            (F.col("events.cpu_time_ms").cast("double") / (1000.0 * 60.0 * 60.0)).alias("cpu_time_hours"),
            F.col("events.peak_user_memory_bytes"),
            F.col("events.physical_input_bytes"),
            F.col("events.written_bytes"),
            (
                (F.col("events.cpu_time_ms").cast("double") / (1000.0 * 60.0 * 60.0) * 0.04)
                + (F.col("events.physical_input_bytes").cast("double") / (1024.0 * 1024.0 * 1024.0 * 1024.0) * 5.0)
            ).alias("estimated_cost_usd"),
            F.col("events.event_date").alias("execution_date"),
        )
    )

    fact_queries.writeTo("silver.fact_query_execution").overwrite(
        F.col("execution_date") == target_date
    )


def bronze_to_silver_table_access(spark: SparkSession, target_date: str):
    """
    Corresponds to: transformations/bronze_to_silver_table_access.sql
    """
    raw_df = (
        spark.table("bronze.trino_query_events")
        .filter(F.col("event_date") == target_date)
        .filter(F.col("inputs_metadata_json").isNotNull())
    )
    uth_df = spark.table("silver.dim_user_team_history")

    parsed_inputs = (
        raw_df.alias("events")
        .join(
            uth_df.alias("user_history"),
            (F.col("events.user_name") == F.col("user_history.user_name"))
            & (F.to_date(F.col("events.created_at")) >= F.col("user_history.valid_from"))
            & (F.to_date(F.col("events.created_at")) < F.col("user_history.valid_to")),
            "left",
        )
        .select(
            F.col("events.query_id"),
            F.col("events.user_name"),
            F.coalesce(F.col("user_history.team_id"), F.lit("unassigned")).alias("team_id"),
            F.col("events.event_date").alias("execution_date"),
            F.explode(F.from_json(F.col("events.inputs_metadata_json"), INPUTS_SCHEMA)).alias("input_element"),
        )
        .select(
            F.col("query_id"),
            F.concat_ws(".", F.col("input_element.catalogName"), F.col("input_element.schemaName"), F.col("input_element.tableName")).alias("table_name"),
            F.col("user_name"),
            F.col("team_id"),
            F.coalesce(F.col("input_element.physicalInputBytes"), F.lit(0)).alias("physical_bytes_read"),
            F.coalesce(F.col("input_element.physicalInputRows"), F.lit(0)).alias("rows_read"),
            F.col("execution_date"),
        )
    )

    parsed_inputs.writeTo("silver.fact_query_table_access").overwrite(
        F.col("execution_date") == target_date
    )


def silver_to_gold_daily_table_usage(spark: SparkSession, target_date: str):
    """
    Corresponds to: transformations/silver_to_gold_daily_table_usage.sql
    """
    access_df = spark.table("silver.fact_query_table_access").filter(
        F.col("execution_date") == target_date
    )

    mart_table = (
        access_df.groupBy("execution_date", "table_name")
        .agg(
            F.countDistinct("user_name").alias("distinct_users_count"),
            F.countDistinct("team_id").alias("distinct_teams_count"),
            F.countDistinct("query_id").alias("total_queries_count"),
            F.sum("physical_bytes_read").alias("total_physical_bytes_read"),
            F.sum("rows_read").alias("total_rows_read"),
        )
    )

    mart_table.writeTo("gold.mart_table_daily_usage").overwrite(
        F.col("execution_date") == target_date
    )


def silver_to_gold_daily_team_resources(spark: SparkSession, target_date: str):
    """
    Corresponds to: transformations/silver_to_gold_daily_team_resources.sql
    """
    queries_df = spark.table("silver.fact_query_execution").filter(
        F.col("execution_date") == target_date
    )

    mart_team = (
        queries_df.groupBy("execution_date", "team_id")
        .agg(
            F.count("query_id").alias("total_queries_count"),
            F.count(F.when(F.col("query_state") == "FINISHED", 1)).alias("successful_queries_count"),
            F.count(F.when(F.col("query_state") != "FINISHED", 1)).alias("failed_queries_count"),
            F.countDistinct("user_name").alias("distinct_active_users"),
            F.sum("cpu_time_hours").alias("total_cpu_time_hours"),
            F.max("peak_user_memory_bytes").alias("peak_memory_bytes"),
            F.sum("physical_input_bytes").alias("total_physical_input_bytes"),
            F.sum("estimated_cost_usd").alias("total_estimated_cost_usd"),
        )
    )

    mart_team.writeTo("gold.mart_team_daily_resource_usage").overwrite(
        F.col("execution_date") == target_date
    )


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target-date", required=True, help="Target date YYYY-MM-DD")
    return parser.parse_args()


def main():
    args = parse_args()
    target_date = args.target_date

    spark = (
        SparkSession.builder.appName("MetaDWH_ETL")
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .getOrCreate()
    )

    bronze_to_silver_queries(spark, target_date)
    bronze_to_silver_table_access(spark, target_date)
    silver_to_gold_daily_table_usage(spark, target_date)
    silver_to_gold_daily_team_resources(spark, target_date)

    spark.stop()


if __name__ == "__main__":
    main()
