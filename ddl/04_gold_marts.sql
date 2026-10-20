-- Daily table usage summary
CREATE TABLE IF NOT EXISTS gold.mart_table_daily_usage (
    execution_date DATE,
    table_name VARCHAR,

    distinct_users_count BIGINT,
    distinct_teams_count BIGINT,
    total_queries_count BIGINT,

    total_physical_bytes_read BIGINT,
    total_rows_read BIGINT
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['execution_date']
);

-- Daily team resource consumption summary
CREATE TABLE IF NOT EXISTS gold.mart_team_daily_resource_usage (
    execution_date DATE,
    team_id VARCHAR,

    total_queries_count BIGINT,
    successful_queries_count BIGINT,
    failed_queries_count BIGINT,
    distinct_active_users BIGINT,

    total_cpu_time_hours DOUBLE,
    peak_memory_bytes BIGINT,
    total_physical_input_bytes BIGINT,
    total_estimated_cost_usd DOUBLE
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['execution_date']
);
