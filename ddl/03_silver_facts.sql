-- Query executions with resource metrics
CREATE TABLE IF NOT EXISTS silver.fact_query_execution (
    query_id VARCHAR,
    user_name VARCHAR,
    team_id VARCHAR,
    source VARCHAR,
    query_state VARCHAR,

    created_at TIMESTAMP(6) WITH TIME ZONE,
    wall_time_ms BIGINT,
    cpu_time_ms BIGINT,
    cpu_time_hours DOUBLE,
    peak_user_memory_bytes BIGINT,

    physical_input_bytes BIGINT,
    written_bytes BIGINT,
    estimated_cost_usd DOUBLE,

    execution_date DATE
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['execution_date']
);

-- Table accesses per query
CREATE TABLE IF NOT EXISTS silver.fact_query_table_access (
    query_id VARCHAR,
    table_name VARCHAR,
    user_name VARCHAR,
    team_id VARCHAR,

    physical_bytes_read BIGINT,
    rows_read BIGINT,

    execution_date DATE
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['execution_date']
);
