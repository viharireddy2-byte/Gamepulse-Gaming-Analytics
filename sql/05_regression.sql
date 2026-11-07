-- Self-contained BigQuery regression fixture. No permanent tables are modified.
CREATE TEMP TABLE fixture_raw AS
WITH rows AS (
 SELECT * FROM UNNEST([
 STRUCT('a1' AS event_id,'A' AS game_name,'u1' AS user_id,0 AS sec,'Session_Started' AS event_name,0.0 AS amount,1 AS revision),
 ('a2','A','u1',1,'FTUE_Stage_Started',0.0,1),
 ('a3','A','u1',2,'FTUE_Stage_Complete',0.0,1),
 ('a4','A','u1',3,'in_app_purchase',4.99,1),
 ('a4','A','u1',3,'in_app_purchase',6.99,2),
 ('a5','A','u1',1803,'Ad_Watched',0.0,1),
 ('b1','B','u1',0,'Session_Started',0.0,1),
 ('b2','B','u1',10,'in_app_purchase',2.0,1),
 ('c1','A','u2',0,'Session_Started',0.0,1),
 ('c2','A','u2',1,'FTUE_Stage_Complete',0.0,1),
 ('c3','A','u2',2,'FTUE_Stage_Started',0.0,1),
 ('c4','A','u2',3,'in_app_purchase',0.0,1)
 ])
)
SELECT event_id,game_name,user_id,event_name,TIMESTAMP_ADD(TIMESTAMP('2020-01-01'),INTERVAL sec SECOND) event,
 TIMESTAMP_ADD(TIMESTAMP('2020-01-02'),INTERVAL revision SECOND) ingested_at,
 TIMESTAMP('2020-01-01') player_first_seen,CAST(amount AS NUMERIC) iap_revenue,
 CAST(IF(event_name='Ad_Watched',0.01,0) AS NUMERIC) ad_revenue,
 CAST(1 AS NUMERIC) install_cost,'Paid' install_source,'test' campaign_name,
 'US' country,'Android' device_platform,'1.0' game_version,1 player_level
FROM rows;

CREATE TEMP TABLE fixture_events AS
WITH deduplicated AS (
 SELECT * EXCEPT(rn) FROM (
 SELECT *, ROW_NUMBER() OVER(PARTITION BY game_name, event_id ORDER BY ingested_at DESC) rn
 FROM fixture_raw) WHERE rn = 1
), gaps AS (
 SELECT *, LAG(event) OVER(PARTITION BY game_name, user_id ORDER BY event, event_id) previous_event
 FROM deduplicated
), numbered AS (
 SELECT *, SUM(IF(previous_event IS NULL OR TIMESTAMP_DIFF(event, previous_event, SECOND) >= 1800,1,0))
 OVER(PARTITION BY game_name,user_id ORDER BY event,event_id ROWS UNBOUNDED PRECEDING) session_number
 FROM gaps
)
SELECT * EXCEPT(previous_event), DATE(event) event_day,
 TO_HEX(SHA256(TO_JSON_STRING(STRUCT(game_name, user_id)))) player_key,
 TO_HEX(SHA256(TO_JSON_STRING(STRUCT(game_name, user_id, session_number)))) unique_session_id
FROM numbered;

CREATE TEMP TABLE fixture_session_facts AS
WITH rollup AS (
 SELECT unique_session_id, player_key, user_id, game_name, MIN(event) session_start, MAX(event) session_end,
 DATE(MIN(event)) session_day, COUNT(*) events_in_session,
 SUM(COALESCE(iap_revenue,0)) session_iap_revenue, SUM(COALESCE(ad_revenue,0)) session_ad_revenue,
 COUNTIF(event_name='Ad_Watched') number_of_ads_shown, COUNTIF(event_name='Level_Up') number_of_level_ups,
 MAX(player_level) highest_level_reached,
 ARRAY_AGG(event_name ORDER BY event,event_id LIMIT 1)[OFFSET(0)] session_first_event,
 ARRAY_AGG(event_name ORDER BY event DESC,event_id DESC LIMIT 1)[OFFSET(0)] session_last_event,
 ARRAY_AGG(STRUCT(country,device_platform,game_version) ORDER BY event,event_id LIMIT 1)[OFFSET(0)] attributes
 FROM fixture_events GROUP BY 1,2,3,4
)
SELECT * EXCEPT(attributes), attributes.*,
 session_iap_revenue+session_ad_revenue session_revenue,
 TIMESTAMP_DIFF(session_end,session_start,SECOND)/60.0 session_length_minutes,
 ROW_NUMBER() OVER(PARTITION BY player_key ORDER BY session_start,unique_session_id) session_sequence_for_user,
 ROW_NUMBER() OVER(PARTITION BY player_key ORDER BY session_start DESC,unique_session_id DESC) inverse_session_sequence_for_user,
 LEAD(session_start) OVER(PARTITION BY player_key ORDER BY session_start,unique_session_id) next_session_start
FROM rollup;

CREATE TEMP TABLE fixture_user_facts AS
WITH player AS (
 SELECT player_key,user_id,game_name,MIN(player_first_seen) player_first_seen,MAX(event) player_last_seen,
 COUNT(DISTINCT DATE(event)) days_played, COUNT(DISTINCT unique_session_id) number_of_sessions,
 SUM(COALESCE(iap_revenue,0)) lifetime_iap_revenue,SUM(COALESCE(ad_revenue,0)) lifetime_ad_revenue,
 MAX(player_level) highest_level_reached,
 COUNTIF(event_name='Level_Up') lifetime_level_ups,
 COUNT(DISTINCT device_platform) number_of_devices_used,
 COUNT(DISTINCT country) number_of_countries_played_in,
 APPROX_TOP_COUNT(device_platform,1)[OFFSET(0)].value most_commonly_used_device,
 APPROX_TOP_COUNT(country,1)[OFFSET(0)].value most_commonly_played_country,
 ARRAY_AGG(STRUCT(install_cost,install_source,campaign_name) ORDER BY event,event_id LIMIT 1)[OFFSET(0)] acquisition
 FROM fixture_events GROUP BY 1,2,3
)
SELECT p.* EXCEPT(acquisition), acquisition.*,
 s.total_session_length,
 lifetime_iap_revenue+lifetime_ad_revenue lifetime_revenue,
 COUNTIF(DATE_DIFF(DATE(e.event),DATE(p.player_first_seen),DAY)=1)>0 d1_retained,
 COUNTIF(DATE_DIFF(DATE(e.event),DATE(p.player_first_seen),DAY)=7)>0 d7_retained,
 COUNTIF(DATE_DIFF(DATE(e.event),DATE(p.player_first_seen),DAY)=14)>0 d14_retained,
 COUNTIF(DATE_DIFF(DATE(e.event),DATE(p.player_first_seen),DAY)=30)>0 d30_retained
,
SUM(IF(DATE_DIFF(DATE(e.event),DATE(p.player_first_seen),DAY) BETWEEN 0 AND 1, COALESCE(e.iap_revenue,0)+COALESCE(e.ad_revenue,0),0)) total_d1_revenue,
SUM(IF(DATE_DIFF(DATE(e.event),DATE(p.player_first_seen),DAY) BETWEEN 0 AND 7, COALESCE(e.iap_revenue,0)+COALESCE(e.ad_revenue,0),0)) total_d7_revenue,
SUM(IF(DATE_DIFF(DATE(e.event),DATE(p.player_first_seen),DAY) BETWEEN 0 AND 14, COALESCE(e.iap_revenue,0)+COALESCE(e.ad_revenue,0),0)) total_d14_revenue,
SUM(IF(DATE_DIFF(DATE(e.event),DATE(p.player_first_seen),DAY) BETWEEN 0 AND 30, COALESCE(e.iap_revenue,0)+COALESCE(e.ad_revenue,0),0)) total_d30_revenue
FROM player p JOIN fixture_events e USING(player_key)
LEFT JOIN (SELECT player_key,SUM(session_length_minutes) total_session_length FROM fixture_session_facts GROUP BY 1) s USING(player_key)
GROUP BY ALL;

CREATE TEMP TABLE fixture_funnel_explorer AS
WITH base AS (
 SELECT * FROM fixture_events
 WHERE TRUE
 AND TRUE
), stage1 AS (
 SELECT unique_session_id,player_key,user_id,game_name, MIN(event) session_start,
 MIN(IF(event_name='Session_Started',event,NULL)) step1 FROM base GROUP BY 1,2,3,4
), stage2 AS (
 SELECT s.*, MIN(IF(b.event_name='FTUE_Stage_Started' AND b.event>s.step1,b.event,NULL)) step2
 FROM stage1 s LEFT JOIN base b USING(unique_session_id) GROUP BY ALL
), stage3 AS (
 SELECT s.*, MIN(IF(b.event_name='FTUE_Stage_Complete' AND b.event>s.step2,b.event,NULL)) step3
 FROM stage2 s LEFT JOIN base b USING(unique_session_id) GROUP BY ALL
), stage4 AS (
 SELECT s.*, MIN(IF(b.event_name='in_app_purchase' AND b.event>s.step3,b.event,NULL)) step4
 FROM stage3 s LEFT JOIN base b USING(unique_session_id) GROUP BY ALL
) SELECT * FROM stage4;

ASSERT (SELECT COUNT(*) FROM fixture_events)=11 AS 'Latest-write dedup failed';
ASSERT (SELECT COUNT(*) FROM fixture_session_facts)=4 AS '30-minute gap or game isolation failed';
ASSERT (SELECT COUNT(*) FROM fixture_user_facts)=3 AS 'Cross-game player isolation failed';
ASSERT (ABS((SELECT SUM(session_revenue) FROM fixture_session_facts)-9.00)<0.000001) AS 'Session purchase or ad revenue lost';
ASSERT (ABS((SELECT SUM(lifetime_revenue) FROM fixture_user_facts)-9.00)<0.000001) AS 'Player lifetime revenue mismatch';
ASSERT (SELECT SUM(events_in_session) FROM fixture_session_facts)=11 AS 'Session event reconciliation failed';
ASSERT (SELECT COUNT(*) FROM fixture_funnel_explorer WHERE step4 IS NOT NULL)=1 AS 'Sequential funnel false positive';
ASSERT (SELECT COUNT(*) FROM fixture_user_facts WHERE d1_retained)=0 AS 'Incorrect exact-day retention';
ASSERT (SELECT MAX(session_sequence_for_user) FROM fixture_session_facts WHERE game_name='A' AND user_id='u1')=2 AS 'Session ordering failed';
