INSERT OVERWRITE gold.mart_team_daily_resource_usage
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
FROM silver.fact_query_execution
WHERE execution_date = DATE '${target_date}'
GROUP BY execution_date, team_id;
