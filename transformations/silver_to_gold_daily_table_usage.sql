INSERT OVERWRITE gold.mart_table_daily_usage
SELECT
    execution_date,
    table_name,
    COUNT(DISTINCT user_name) AS distinct_users_count,
    COUNT(DISTINCT team_id) AS distinct_teams_count,
    COUNT(DISTINCT query_id) AS total_queries_count,
    SUM(physical_bytes_read) AS total_physical_bytes_read,
    SUM(rows_read) AS total_rows_read
FROM silver.fact_query_table_access
WHERE execution_date = DATE '${target_date}'
GROUP BY execution_date, table_name;
