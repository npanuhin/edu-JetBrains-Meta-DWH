-- How many distinct users queried the table X during a given period?
-- Let X = iceberg.product_analytics.events_log

-- Exact answer
SELECT
    table_name,
    COUNT(DISTINCT user_name) AS distinct_users_count,
    COUNT(DISTINCT query_id) AS total_queries_count
FROM silver.fact_query_table_access
WHERE table_name = 'iceberg.product_analytics.events_log'
  AND execution_date BETWEEN DATE '2026-09-01' AND DATE '2026-09-30'
GROUP BY table_name;


-- Historical perspective
SELECT
    execution_date,
    distinct_users_count,
    total_queries_count,
    ROUND(total_physical_bytes_read / (1024.0 * 1024.0 * 1024.0), 2) AS total_read_gb
FROM gold.mart_table_daily_usage
WHERE table_name = 'iceberg.product_analytics.events_log'
  AND execution_date BETWEEN DATE '2026-09-01' AND DATE '2026-09-30'
ORDER BY execution_date;
