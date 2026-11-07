-- Opt-in publication gate for an already loaded, quiescent batch.
-- Existing 02_seed.sql is unchanged for compatibility. New integrations should
-- publish here only after ingestion has completed; do not write concurrently.
BEGIN TRANSACTION;
ASSERT (SELECT COUNT(*) FROM gamepulse.raw_events WHERE event>ingested_at OR player_first_seen>event)=0 AS 'Invalid timestamp order';
ASSERT (SELECT COUNT(*) FROM gamepulse.raw_events WHERE user_id='' OR game_name='' OR event_id='')=0 AS 'Empty business key';
ASSERT (SELECT COUNT(*) FROM gamepulse.raw_events WHERE iap_revenue<0 OR ad_revenue<0 OR install_cost<0)=0 AS 'Negative revenue or cost';
ASSERT (SELECT COUNT(*) FROM (SELECT game_name,user_id FROM gamepulse.raw_events GROUP BY 1,2
 HAVING COUNT(DISTINCT player_first_seen)>1 OR COUNT(DISTINCT install_cost)>1
 OR COUNT(DISTINCT install_source)>1 OR COUNT(DISTINCT campaign_name)>1))=0 AS 'Attribution drift';
ASSERT (SELECT COUNT(*) FROM (SELECT game_name,event_id,ingested_at FROM gamepulse.raw_events
 GROUP BY 1,2,3 HAVING COUNT(DISTINCT TO_JSON_STRING(STRUCT(event,user_id,event_name,player_first_seen,install_cost,install_source,campaign_name,iap_revenue,ad_revenue,player_level,country,device_platform,game_version,continent,region,device_brand,device_language,device_model,device_os_version,ad_network,campaign_id,campaign_type)))>1))=0 AS 'Ambiguous duplicate revisions';
INSERT INTO gamepulse.pipeline_state VALUES(GENERATE_UUID(),CURRENT_TIMESTAMP(),'complete');
COMMIT TRANSACTION;
