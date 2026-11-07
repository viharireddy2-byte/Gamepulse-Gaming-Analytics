view: events {
 derived_table: {
datagroup_trigger: events_raw
partition_keys: ["event_day"]
cluster_keys: ["game_name", "user_id"]
sql: WITH deduplicated AS (
 SELECT * EXCEPT(rn) FROM (
 SELECT *, ROW_NUMBER() OVER(PARTITION BY game_name, event_id ORDER BY ingested_at DESC) rn
 FROM `gamepulse.raw_events`) WHERE rn = 1
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
FROM numbered ;;
 }
  dimension: event_id { type: string  sql: ${TABLE}.event_id ;; }
  dimension: user_id { type: string  sql: ${TABLE}.user_id ;; }
  dimension: game_name { type: string  sql: ${TABLE}.game_name ;; }
  dimension: event_name { type: string  sql: ${TABLE}.event_name ;; }
  dimension: country { type: string  sql: ${TABLE}.country ;; }
  dimension: device_platform { type: string  sql: ${TABLE}.device_platform ;; }
  dimension: game_version { type: string  sql: ${TABLE}.game_version ;; }
  dimension: install_source { type: string  sql: ${TABLE}.install_source ;; }
  dimension: campaign_name { type: string  sql: ${TABLE}.campaign_name ;; }
  dimension: unique_session_id { type: string  sql: ${TABLE}.unique_session_id ;; }
  dimension: player_key { type: string  sql: ${TABLE}.player_key ;; }
  dimension: event_key { type: string primary_key: yes hidden: yes sql: TO_HEX(SHA256(TO_JSON_STRING(STRUCT(${game_name}, ${event_id})))) ;; }
  dimension_group: event { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.event ;; }
  dimension_group: player_first_seen { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.player_first_seen ;; }
  dimension: iap_revenue { type: number  sql: ${TABLE}.iap_revenue ;; }
  dimension: ad_revenue { type: number  sql: ${TABLE}.ad_revenue ;; }
  dimension: install_cost { type: number  sql: ${TABLE}.install_cost ;; }
  dimension: player_level { type: number  sql: ${TABLE}.player_level ;; }
  dimension: revenue { type: number  sql: COALESCE(${iap_revenue},0) + COALESCE(${ad_revenue},0) ;; }
  measure: event_count { type: count sql: 1 ;;  }
  measure: active_users { type: count_distinct sql: ${player_key} ;;  }
  measure: number_of_sessions { type: count_distinct sql: ${unique_session_id} ;;  }
  measure: total_revenue { type: sum sql: ${revenue} ;; value_format_name: usd }
  measure: total_iap_revenue { type: sum sql: ${iap_revenue} ;; value_format_name: usd }
  measure: total_ad_revenue { type: sum sql: ${ad_revenue} ;; value_format_name: usd }
  measure: paying_users { type: count_distinct sql: IF(${iap_revenue}>0,${player_key},NULL) ;;  }
  measure: arpu { type: number sql: SAFE_DIVIDE(${total_revenue},${active_users}) ;; value_format_name: decimal_2 }
  measure: arppu { type: number sql: SAFE_DIVIDE(${total_iap_revenue},${paying_users}) ;; value_format_name: decimal_2 }
  measure: payer_conversion { type: number sql: SAFE_DIVIDE(${paying_users},${active_users}) ;; value_format_name: decimal_2 }


dimension: continent { type: string sql: ${TABLE}.continent ;; }
dimension: region { type: string sql: ${TABLE}.region ;; }
dimension: device_brand { type: string sql: ${TABLE}.device_brand ;; }
dimension: device_language { type: string sql: ${TABLE}.device_language ;; }
dimension: device_model { type: string sql: ${TABLE}.device_model ;; }
dimension: device_os_version { type: string sql: ${TABLE}.device_os_version ;; }
dimension: ad_network { type: string sql: ${TABLE}.ad_network ;; }
dimension: campaign_id { type: string sql: ${TABLE}.campaign_id ;; }
dimension: campaign_type { type: string sql: ${TABLE}.campaign_type ;; }
dimension: retention_day { type: number sql: DATE_DIFF(${event_date},${player_first_seen_date},DAY) ;; }
dimension: is_first_session { type: yesno sql: ${TABLE}.session_number=1 ;; }
dimension: install_group { type: string sql: IF(${install_source}='Organic','Organic','Paid') ;; }
measure: number_of_new_users { type: count_distinct sql: IF(${retention_day}=0,${player_key},NULL) ;; }
measure: number_of_ads_shown { type: sum sql: IF(${event_name}='Ad_Watched',1,0) ;; }
measure: number_of_level_ups { type: sum sql: IF(${event_name}='Level_Up',1,0) ;; }
measure: number_of_iap_purchases { type: sum sql: IF(${iap_revenue}>0,1,0) ;; }
measure: transactions_per_spender { type: number sql: SAFE_DIVIDE(${number_of_iap_purchases},${paying_users}) ;; }
measure: number_of_time_buckets { type: count_distinct sql: TO_JSON_STRING(STRUCT(${player_key},DIV(UNIX_SECONDS(${event_raw}),120))) ;; }
measure: approximate_usage_in_minutes { type: number sql: ${number_of_time_buckets}*2 ;; }
measure: average_usage_minutes_per_user { type: number sql: SAFE_DIVIDE(${approximate_usage_in_minutes},${active_users}) ;; }
parameter: drill_by { type: unquoted default_value: "game_name"
allowed_value: { label: "Game Name" value: "game_name" }
allowed_value: { label: "Country" value: "country" }
allowed_value: { label: "Device Platform" value: "device_platform" }
allowed_value: { label: "Campaign Name" value: "campaign_name" }
}

dimension: drill_field { type: string sql: ${TABLE}.{% parameter drill_by %} ;; }
}
