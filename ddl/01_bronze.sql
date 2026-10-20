-- Raw query events collected from Trino EventListener
CREATE TABLE IF NOT EXISTS bronze.trino_query_events (
    query_id VARCHAR,
    query_text VARCHAR,
    user_name VARCHAR,
    source VARCHAR,
    query_state VARCHAR,

    created_at TIMESTAMP(6) WITH TIME ZONE,
    execution_start_at TIMESTAMP(6) WITH TIME ZONE,
    end_at TIMESTAMP(6) WITH TIME ZONE,
    wall_time_ms BIGINT,
    cpu_time_ms BIGINT,

    peak_user_memory_bytes BIGINT,
    physical_input_bytes BIGINT,
    written_bytes BIGINT,

    -- JSON array of tables accessed:
    -- [{"catalogName": "iceberg", "schemaName": "prod", "tableName": "events_log", "physicalInputBytes": 8388608}]
    inputs_metadata_json VARCHAR,

    event_date DATE
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['event_date']
);
