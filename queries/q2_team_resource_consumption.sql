-- How many resources did the team Y consume during that period?
-- Let Y = product-analytics

-- Exact answer
SELECT
    team_id,
    SUM(total_queries_count) AS total_queries,
    SUM(successful_queries_count) AS successful_queries,
    SUM(failed_queries_count) AS failed_queries,
    ROUND(SUM(total_cpu_time_hours), 2) AS total_cpu_hours,
    ROUND(MAX(peak_memory_bytes) / (1024.0 * 1024.0), 2) AS max_peak_memory_mb,
    ROUND(SUM(total_physical_input_bytes) / (1024.0 * 1024.0 * 1024.0), 2) AS total_scanned_gb,
    ROUND(SUM(total_estimated_cost_usd), 2) AS total_cost_usd
FROM gold.mart_team_daily_resource_usage
WHERE team_id = 'product-analytics'
  AND execution_date BETWEEN DATE '2026-09-01' AND DATE '2026-09-30'
GROUP BY team_id;


-- Historical perspective
SELECT
    execution_date,
    team_id,
    total_queries_count AS total_queries,
    successful_queries_count AS successful_queries,
    failed_queries_count AS failed_queries,
    ROUND(total_cpu_time_hours, 2) AS cpu_hours,
    ROUND(peak_memory_bytes / (1024.0 * 1024.0), 2) AS peak_memory_mb,
    ROUND(total_physical_input_bytes / (1024.0 * 1024.0 * 1024.0), 2) AS scanned_gb,
    ROUND(total_estimated_cost_usd, 2) AS cost_usd
FROM gold.mart_team_daily_resource_usage
WHERE team_id = 'product-analytics'
  AND execution_date BETWEEN DATE '2026-09-01' AND DATE '2026-09-30'
ORDER BY execution_date;
