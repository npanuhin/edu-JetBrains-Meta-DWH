-- How many resources did team Y consume during that period?
-- Let Y = product-analytics

SELECT
    team_id,
    SUM(total_queries_count) AS total_queries,
    SUM(successful_queries_count) AS successful_queries,
    SUM(failed_queries_count) AS failed_queries,
    ROUND(SUM(total_cpu_time_hours), 4) AS total_cpu_hours,
    ROUND(MAX(peak_memory_bytes) / (1024.0 * 1024.0), 2) AS max_peak_memory_mb,
    ROUND(SUM(total_physical_input_bytes) / (1024.0 * 1024.0 * 1024.0), 3) AS total_scanned_gb,
    ROUND(SUM(total_estimated_cost_usd), 4) AS total_cost_usd
FROM gold_mart_team_daily_resource_usage
WHERE team_id = 'product-analytics'
  AND execution_date BETWEEN '2026-09-01' AND '2026-09-30'
GROUP BY team_id;
