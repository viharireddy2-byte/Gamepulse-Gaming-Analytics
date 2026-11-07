ASSERT (SELECT COUNT(*) FROM gamepulse.raw_events WHERE event>ingested_at OR player_first_seen>event)=0 AS 'Invalid timestamp ordering';
ASSERT (SELECT COUNT(*) FROM gamepulse.raw_events WHERE user_id='' OR game_name='' OR event_id='')=0 AS 'Empty business key';
ASSERT (SELECT COUNT(*) FROM gamepulse.raw_events WHERE iap_revenue<0 OR ad_revenue<0 OR install_cost<0)=0 AS 'Negative amount outside supported revenue contract';
ASSERT (SELECT COUNT(*) FROM (
 SELECT game_name,user_id FROM gamepulse.raw_events GROUP BY 1,2
 HAVING COUNT(DISTINCT player_first_seen)>1 OR COUNT(DISTINCT install_cost)>1
 OR COUNT(DISTINCT install_source)>1 OR COUNT(DISTINCT campaign_name)>1))=0 AS 'Inconsistent acquisition metadata';
ASSERT (SELECT COUNT(*) FROM (
 SELECT game_name,event_id FROM gamepulse.raw_events GROUP BY 1,2 HAVING COUNT(*)>1))=0 AS 'Duplicate event identifiers: reconcile upstream or confirm latest-ingestion deduplication';
ASSERT (SELECT COUNT(*) FROM gamepulse.pipeline_state WHERE status='complete')>0 AS 'Missing publication watermark';
