-- Synthetic, deterministic workload. Set to 50000000 for the scale scenario.
-- Default: 100k rows. Separate INSERT transactions are published only after validation.
DECLARE event_count INT64 DEFAULT 100000;
DECLARE base_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 38 DAY);
ASSERT event_count BETWEEN 1 AND 50000000 AS 'Supported workload: 1 to 50M';
-- Idempotent for this synthetic namespace; real data is untouched.
DELETE FROM gamepulse.raw_events WHERE STARTS_WITH(event_id,'synthetic-');
INSERT INTO gamepulse.raw_events (event_id,event,ingested_at,user_id,game_name,event_name,player_first_seen,country,device_platform,game_version,install_source,campaign_name,install_cost,iap_revenue,ad_revenue,player_level)
WITH ids AS (
 SELECT a*10000+b id FROM UNNEST(GENERATE_ARRAY(0,DIV(event_count-1,10000))) a
 CROSS JOIN UNNEST(GENERATE_ARRAY(0,9999)) b WHERE a*10000+b<event_count
), workload AS (
 SELECT *, DIV(id,100) player, MOD(id,100) ordinal FROM ids
), timed AS (
 SELECT *, TIMESTAMP_ADD(TIMESTAMP(DATE_ADD(base_date,INTERVAL MOD(player,30) DAY)),
 INTERVAL (DIV(ordinal,10)*86400+MOD(ordinal,10)*60) SECOND) event_time FROM workload
)
SELECT CONCAT('synthetic-',CAST(id AS STRING)),event_time,CURRENT_TIMESTAMP(),
 CONCAT('player-',CAST(player AS STRING)), IF(MOD(player,2)=0,'Orbit Quest','Harvest Valley'),
 ['Session_Started','FTUE_Stage_Started','FTUE_Stage_Complete','Match_Started','Match_Ended',
 'Level_Up','Ad_Watched','IAP_Started','in_app_purchase','Gem_Spend'][OFFSET(MOD(ordinal,10))],
 TIMESTAMP(DATE_ADD(base_date,INTERVAL MOD(player,30) DAY)),
 ['US','GB','IN','CA'][OFFSET(MOD(player,4))],IF(MOD(player,2)=0,'Android','iOS'),'1.0.0',
 IF(MOD(player,5)=0,'Organic','Paid Search'),CONCAT('campaign-',CAST(MOD(player,8) AS STRING)),
 CAST(IF(MOD(player,5)=0,0,1.25) AS NUMERIC),
 CAST(IF(MOD(ordinal,10)=8 AND MOD(player,7)=0,4.99,0) AS NUMERIC),
 CAST(IF(MOD(ordinal,10)=6,0.015,0) AS NUMERIC),1+DIV(ordinal,10)
FROM timed;
-- Validate before publishing the cache invalidation watermark.
ASSERT (SELECT COUNT(*) FROM gamepulse.raw_events WHERE STARTS_WITH(event_id,'synthetic-'))=event_count AS 'Seed row count mismatch';
INSERT INTO gamepulse.pipeline_state VALUES(GENERATE_UUID(),CURRENT_TIMESTAMP(),'complete');
