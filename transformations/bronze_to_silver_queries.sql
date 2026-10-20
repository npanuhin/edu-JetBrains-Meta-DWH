INSERT OVERWRITE silver.fact_query_execution
SELECT
    events.query_id,
    events.user_name,
    COALESCE(user_history.team_id, 'unassigned') AS team_id,
    events.source,
    events.query_state,
    events.created_at,
    events.wall_time_ms,
    events.cpu_time_ms,
    CAST(events.cpu_time_ms AS DOUBLE) / (1000.0 * 60.0 * 60.0) AS cpu_time_hours,
    events.peak_user_memory_bytes,
    events.physical_input_bytes,
    events.written_bytes,
    -- Sample cost model for illustration: $0.04 per CPU hour + $5.00 per TB scanned from S3
    (CAST(events.cpu_time_ms AS DOUBLE) / (1000.0 * 60.0 * 60.0) * 0.04) +
    (CAST(events.physical_input_bytes AS DOUBLE) / (1024.0 * 1024.0 * 1024.0 * 1024.0) * 5.0) AS estimated_cost_usd,
    events.event_date AS execution_date
FROM bronze.trino_query_events events
LEFT JOIN silver.dim_user_team_history user_history
    ON events.user_name = user_history.user_name
   -- Use created_at instead of event_date so queries crossing midnight attribute to team at start time
   AND CAST(events.created_at AS DATE) >= user_history.valid_from
   AND CAST(events.created_at AS DATE) < user_history.valid_to
WHERE events.event_date = DATE '${target_date}';
