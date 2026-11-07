-- Additive demo namespace: bi-demo-* events and bi-player-* users.
-- Does not replace or modify the original seed script or its synthetic-* rows.
DECLARE player_count INT64 DEFAULT 5000;
DECLARE anchor_date DATE DEFAULT DATE_SUB(CURRENT_DATE(),INTERVAL 1 DAY);
CREATE TEMP FUNCTION bucket(s STRING) AS (MOD(MOD(FARM_FINGERPRINT(s),100)+100,100));
ASSERT player_count BETWEEN 100 AND 500000 AS 'Choose 100 to 500000 players';
BEGIN TRANSACTION;
DELETE FROM gamepulse.raw_events WHERE STARTS_WITH(event_id,'bi-demo-');
INSERT INTO gamepulse.raw_events (event_id,event,ingested_at,user_id,game_name,event_name,player_first_seen,country,device_platform,game_version,install_source,campaign_name,install_cost,iap_revenue,ad_revenue,player_level)
WITH players AS (
 SELECT id,CONCAT('bi-player-',CAST(id AS STRING)) user_id,
 IF(bucket(CONCAT('game-',CAST(id AS STRING)))<50,'Orbit Quest','Harvest Valley') game_name,
 DATE_SUB(anchor_date,INTERVAL bucket(CONCAT('age-',CAST(id AS STRING))) DAY) first_day,
 IF(bucket(CONCAT('channel-',CAST(id AS STRING)))<25,'Organic','Paid Search') source,
 CONCAT('campaign-',CAST(MOD(bucket(CONCAT('campaign-',CAST(id AS STRING))),8) AS STRING)) campaign
 FROM UNNEST(GENERATE_ARRAY(0,player_count-1)) id
), candidates AS (
 SELECT *,day_number,DATE_ADD(first_day,INTERVAL day_number DAY) activity_day,
 CONCAT(CAST(id AS STRING),'-',CAST(day_number AS STRING)) session_key
 FROM players CROSS JOIN UNNEST(GENERATE_ARRAY(0,45)) day_number
 WHERE DATE_ADD(first_day,INTERVAL day_number DAY)<=anchor_date
), sessions AS (
 SELECT *,bucket(CONCAT('funnel-',session_key)) funnel_score,
 bucket(CONCAT('payer-',session_key)) payer_score
 FROM candidates
 WHERE day_number=0 OR bucket(CONCAT('return-',session_key)) <
  5+CAST(75*EXP(-day_number/10.0) AS INT64)
), expanded AS (
 SELECT s.*,stage,event_label
 FROM sessions s CROSS JOIN UNNEST(['Session_Started','FTUE_Stage_Started','FTUE_Stage_Complete','in_app_purchase','Ad_Watched']) event_label WITH OFFSET stage
 WHERE stage=0 OR (stage=1 AND funnel_score<90) OR (stage=2 AND funnel_score<70)
 OR (stage=3 AND funnel_score<70 AND payer_score<12)
 OR (stage=4 AND bucket(CONCAT('ad-',session_key))<65)
)
SELECT CONCAT('bi-demo-',session_key,'-',CAST(stage AS STRING)),
 TIMESTAMP_ADD(TIMESTAMP(activity_day),INTERVAL (36000+stage*60+bucket(CONCAT('timing-',session_key))*stage) SECOND),
 CURRENT_TIMESTAMP(),user_id,game_name,event_label,TIMESTAMP(first_day),
 ['US','GB','IN','CA'][OFFSET(MOD(bucket(CONCAT('country-',CAST(id AS STRING))),4))],
 IF(bucket(CONCAT('platform-',CAST(id AS STRING)))<50,'Android','iOS'),'2.0.0',source,campaign,
 CAST(IF(source='Organic',0,0.75+MOD(bucket(CONCAT('cost-',CAST(id AS STRING))),6)*0.5) AS NUMERIC),
 CAST(IF(stage=3,IF(payer_score<2,49.99,4.99),0) AS NUMERIC),
 CAST(IF(stage=4,0.015,0) AS NUMERIC),1+DIV(day_number,3)
FROM expanded;
ASSERT (SELECT COUNT(DISTINCT user_id) FROM gamepulse.raw_events WHERE STARTS_WITH(event_id,'bi-demo-'))=player_count AS 'Missing demo players';
ASSERT (SELECT COUNT(*) FROM (SELECT game_name,event_id FROM gamepulse.raw_events WHERE STARTS_WITH(event_id,'bi-demo-') GROUP BY 1,2 HAVING COUNT(*)>1))=0 AS 'Duplicate demo event keys';
ASSERT (SELECT COUNT(*) FROM gamepulse.raw_events WHERE STARTS_WITH(event_id,'bi-demo-') AND (event>ingested_at OR player_first_seen>event OR iap_revenue<0 OR ad_revenue<0 OR install_cost<0))=0 AS 'Invalid demo fact';
INSERT INTO gamepulse.pipeline_state VALUES(GENERATE_UUID(),CURRENT_TIMESTAMP(),'complete');
COMMIT TRANSACTION;
