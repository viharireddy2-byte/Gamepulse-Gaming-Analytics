-- Run baseline and optimized queries separately with cache disabled.
-- Same metric and time range; only the predicate changes.
-- Baseline: expression prevents normal date partition pruning.
SELECT game_name,COUNT(*) events,SUM(iap_revenue+ad_revenue) revenue
FROM gamepulse.raw_events
WHERE FORMAT_TIMESTAMP('%F',event)>=CAST(DATE_SUB(CURRENT_DATE(),INTERVAL 7 DAY) AS STRING)
GROUP BY 1;
-- Optimized: direct timestamp range, eligible for partition pruning.
SELECT game_name,COUNT(*) events,SUM(iap_revenue+ad_revenue) revenue
FROM gamepulse.raw_events
WHERE event>=TIMESTAMP(DATE_SUB(CURRENT_DATE(),INTERVAL 7 DAY)) GROUP BY 1;
-- Job evidence: execute in the same region as the dataset.
SELECT job_id,creation_time,total_bytes_processed,total_slot_ms,cache_hit,
 TIMESTAMP_DIFF(end_time,start_time,MILLISECOND) elapsed_ms,query
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_USER
WHERE creation_time>TIMESTAMP_SUB(CURRENT_TIMESTAMP(),INTERVAL 1 DAY)
 AND job_type='QUERY' ORDER BY creation_time DESC LIMIT 50;
