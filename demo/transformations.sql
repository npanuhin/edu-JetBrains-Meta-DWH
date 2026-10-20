-- Demo ETL transformations

-- 1. Fact Query Execution (attributing team by created_at)
INSERT INTO silver_fact_query_execution
SELECT
    events.query_id,
    events.user_name,
    COALESCE(user_history.team_id, 'unassigned') AS team_id,
    events.source,
    events.query_state,
    events.created_at,
    events.wall_time_ms,
    events.cpu_time_ms,
    events.cpu_time_ms / (1000.0 * 60.0 * 60.0) AS cpu_time_hours,
    events.peak_user_memory_bytes,
    events.physical_input_bytes,
    events.written_bytes,
    (events.cpu_time_ms / (1000.0 * 60.0 * 60.0) * 0.04) +
    (events.physical_input_bytes / (1024.0 * 1024.0 * 1024.0 * 1024.0) * 5.0) AS estimated_cost_usd,
    events.event_date AS execution_date
FROM bronze_trino_query_events events
LEFT JOIN silver_dim_user_team_history user_history
    ON events.user_name = user_history.user_name
   AND date(events.created_at) >= user_history.valid_from
   AND date(events.created_at) < user_history.valid_to;

-- 2. Fact Query Table Access (unnesting JSON inputs via SQLite json_each)
INSERT INTO silver_fact_query_table_access
SELECT
    events.query_id,
    json_extract(input_element.value, '$.catalogName') || '.' ||
    json_extract(input_element.value, '$.schemaName') || '.' ||
    json_extract(input_element.value, '$.tableName') AS table_name,
    events.user_name,
    COALESCE(user_history.team_id, 'unassigned') AS team_id,
    COALESCE(json_extract(input_element.value, '$.physicalInputBytes'), 0) AS physical_bytes_read,
    COALESCE(json_extract(input_element.value, '$.physicalInputRows'), 0) AS rows_read,
    events.event_date AS execution_date
FROM bronze_trino_query_events events
JOIN json_each(events.inputs_metadata_json) input_element
LEFT JOIN silver_dim_user_team_history user_history
    ON events.user_name = user_history.user_name
   AND date(events.created_at) >= user_history.valid_from
   AND date(events.created_at) < user_history.valid_to;

-- 3. Gold Mart Table Daily Usage
INSERT INTO gold_mart_table_daily_usage
SELECT
    execution_date,
    table_name,
    COUNT(DISTINCT user_name) AS distinct_users_count,
    COUNT(DISTINCT team_id) AS distinct_teams_count,
    COUNT(DISTINCT query_id) AS total_queries_count,
    SUM(physical_bytes_read) AS total_physical_bytes_read,
    SUM(rows_read) AS total_rows_read
FROM silver_fact_query_table_access
GROUP BY execution_date, table_name;

-- 4. Gold Mart Team Daily Resource Usage
INSERT INTO gold_mart_team_daily_resource_usage
SELECT
    execution_date,
    team_id,
    COUNT(query_id) AS total_queries_count,
    COUNT(CASE WHEN query_state = 'FINISHED' THEN 1 END) AS successful_queries_count,
    COUNT(CASE WHEN query_state != 'FINISHED' THEN 1 END) AS failed_queries_count,
    COUNT(DISTINCT user_name) AS distinct_active_users,
    SUM(cpu_time_hours) AS total_cpu_time_hours,
    MAX(peak_user_memory_bytes) AS peak_memory_bytes,
    SUM(physical_input_bytes) AS total_physical_input_bytes,
    SUM(estimated_cost_usd) AS total_estimated_cost_usd
FROM silver_fact_query_execution
GROUP BY execution_date, team_id;
