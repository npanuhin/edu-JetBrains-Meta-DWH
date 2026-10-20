INSERT OVERWRITE silver.fact_query_table_access
WITH filtered_events AS (
    SELECT
        events.query_id,
        events.user_name,
        COALESCE(user_history.team_id, 'unassigned') AS team_id,
        events.event_date AS execution_date,
        events.inputs_metadata_json
    FROM bronze.trino_query_events events
    LEFT JOIN silver.dim_user_team_history user_history
        ON events.user_name = user_history.user_name
       -- Use created_at instead of event_date so queries crossing midnight attribute to team at start time
       AND CAST(events.created_at AS DATE) >= user_history.valid_from
       AND CAST(events.created_at AS DATE) < user_history.valid_to
    WHERE events.event_date = DATE '${target_date}'
      AND events.inputs_metadata_json IS NOT NULL
)
SELECT
    filtered_events.query_id,
    CONCAT(
        CAST(json_extract_scalar(input_elem, '$.catalogName') AS VARCHAR), '.',
        CAST(json_extract_scalar(input_elem, '$.schemaName') AS VARCHAR), '.',
        CAST(json_extract_scalar(input_elem, '$.tableName') AS VARCHAR)
    ) AS table_name,
    filtered_events.user_name,
    filtered_events.team_id,
    COALESCE(TRY_CAST(json_extract_scalar(input_elem, '$.physicalInputBytes') AS BIGINT), 0) AS physical_bytes_read,
    COALESCE(TRY_CAST(json_extract_scalar(input_elem, '$.physicalInputRows') AS BIGINT), 0) AS rows_read,
    filtered_events.execution_date
FROM filtered_events
CROSS JOIN UNNEST(CAST(json_parse(filtered_events.inputs_metadata_json) AS ARRAY(JSON))) AS unnested_inputs(input_elem);
