-- Extra queries

-- 1) Tables with no queries in the last 90 days (potentially unused)
SELECT
    tables.table_name,
    tables.owner_team_id,
    MAX(usage.execution_date) AS last_accessed_date
FROM silver.dim_table tables
LEFT JOIN gold.mart_table_daily_usage usage
    ON tables.table_name = usage.table_name
GROUP BY tables.table_name, tables.owner_team_id
HAVING MAX(usage.execution_date) < CURRENT_DATE - INTERVAL '90' DAY
    OR MAX(usage.execution_date) IS NULL
ORDER BY last_accessed_date ASC NULLS FIRST;


-- 2) Top queries by CPU consumption in the last 7 days
SELECT
    query_id,
    user_name,
    team_id,
    execution_date,
    ROUND(cpu_time_hours, 2) AS cpu_time_hours,
    ROUND(physical_input_bytes / (1024.0 * 1024.0 * 1024.0), 2) AS scanned_gb,
    query_state
FROM silver.fact_query_execution
WHERE execution_date >= CURRENT_DATE - INTERVAL '7' DAY
ORDER BY cpu_time_hours DESC
LIMIT 10;


-- 3) Top tables by scanned volume in the last 30 days
SELECT
    table_name,
    SUM(total_queries_count) AS total_queries,
    ROUND(SUM(total_physical_bytes_read) / (1024.0 * 1024.0 * 1024.0), 2) AS total_scanned_gb
FROM gold.mart_table_daily_usage
WHERE execution_date >= CURRENT_DATE - INTERVAL '30' DAY
GROUP BY table_name
ORDER BY total_scanned_gb DESC
LIMIT 10;
