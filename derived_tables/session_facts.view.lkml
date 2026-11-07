view: session_facts {
 derived_table: {
datagroup_trigger: events_raw
partition_keys: ["session_day"]
cluster_keys: ["game_name", "user_id"]
sql: WITH rollup AS (
 SELECT unique_session_id, player_key, user_id, game_name, MIN(event) session_start, MAX(event) session_end,
 DATE(MIN(event)) session_day, COUNT(*) events_in_session,
 SUM(COALESCE(iap_revenue,0)) session_iap_revenue, SUM(COALESCE(ad_revenue,0)) session_ad_revenue,
 COUNTIF(event_name='Ad_Watched') number_of_ads_shown, COUNTIF(event_name='Level_Up') number_of_level_ups,
 MAX(player_level) highest_level_reached,
 ARRAY_AGG(event_name ORDER BY event,event_id LIMIT 1)[OFFSET(0)] session_first_event,
 ARRAY_AGG(event_name ORDER BY event DESC,event_id DESC LIMIT 1)[OFFSET(0)] session_last_event,
 ARRAY_AGG(STRUCT(country,device_platform,game_version) ORDER BY event,event_id LIMIT 1)[OFFSET(0)] attributes
 FROM ${events.SQL_TABLE_NAME} GROUP BY 1,2,3,4
)
SELECT * EXCEPT(attributes), attributes.*,
 session_iap_revenue+session_ad_revenue session_revenue,
 TIMESTAMP_DIFF(session_end,session_start,SECOND)/60.0 session_length_minutes,
 ROW_NUMBER() OVER(PARTITION BY player_key ORDER BY session_start,unique_session_id) session_sequence_for_user,
 ROW_NUMBER() OVER(PARTITION BY player_key ORDER BY session_start DESC,unique_session_id DESC) inverse_session_sequence_for_user,
 LEAD(session_start) OVER(PARTITION BY player_key ORDER BY session_start,unique_session_id) next_session_start
FROM rollup ;;
 }
  dimension: unique_session_id { type: string primary_key: yes sql: ${TABLE}.unique_session_id ;; }
  dimension: player_key { type: string  sql: ${TABLE}.player_key ;; }
  dimension: user_id { type: string  sql: ${TABLE}.user_id ;; }
  dimension: game_name { type: string  sql: ${TABLE}.game_name ;; }
  dimension: country { type: string  sql: ${TABLE}.country ;; }
  dimension: device_platform { type: string  sql: ${TABLE}.device_platform ;; }
  dimension: game_version { type: string  sql: ${TABLE}.game_version ;; }
  dimension: session_first_event { type: string  sql: ${TABLE}.session_first_event ;; }
  dimension: session_last_event { type: string  sql: ${TABLE}.session_last_event ;; }
  dimension_group: session_start { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.session_start ;; }
  dimension_group: session_end { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.session_end ;; }
  dimension_group: next_session_start { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.next_session_start ;; }
  dimension: events_in_session { type: number  sql: ${TABLE}.events_in_session ;; }
  dimension: session_revenue { type: number  sql: ${TABLE}.session_revenue ;; }
  dimension: session_iap_revenue { type: number  sql: ${TABLE}.session_iap_revenue ;; }
  dimension: session_ad_revenue { type: number  sql: ${TABLE}.session_ad_revenue ;; }
  dimension: number_of_ads_shown { type: number  sql: ${TABLE}.number_of_ads_shown ;; }
  dimension: number_of_level_ups { type: number  sql: ${TABLE}.number_of_level_ups ;; }
  dimension: highest_level_reached { type: number  sql: ${TABLE}.highest_level_reached ;; }
  dimension: session_length_minutes { type: number  sql: ${TABLE}.session_length_minutes ;; }
  dimension: session_sequence_for_user { type: number  sql: ${TABLE}.session_sequence_for_user ;; }
  dimension: inverse_session_sequence_for_user { type: number  sql: ${TABLE}.inverse_session_sequence_for_user ;; }
  dimension: is_last_session { type: yesno  sql: ${inverse_session_sequence_for_user}=1 ;; }
  dimension: is_first_session { type: yesno  sql: ${session_sequence_for_user}=1 ;; }
  measure: number_of_sessions { type: count sql: 1 ;;  }
  measure: total_revenue { type: sum sql: ${session_revenue} ;;  }
  measure: average_session_length_minutes { type: average sql: ${session_length_minutes} ;;  }

}
