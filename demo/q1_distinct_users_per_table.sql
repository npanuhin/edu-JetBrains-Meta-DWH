-- How many distinct users queried table X during a given period?
-- Let X = iceberg.product_analytics.events_log

SELECT
    table_name,
    COUNT(DISTINCT user_name) AS distinct_users_count,
    COUNT(DISTINCT query_id) AS total_queries_count
FROM silver_fact_query_table_access
WHERE table_name = 'iceberg.product_analytics.events_log'
  AND execution_date BETWEEN '2026-09-01' AND '2026-09-30'
GROUP BY table_name;
