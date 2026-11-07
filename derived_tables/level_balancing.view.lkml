view: level_balancing {
 derived_table: {
datagroup_trigger: events_raw
sql: SELECT player_key,user_id,game_name,player_level,COUNT(*) events_at_level,
 LEAST(TIMESTAMP_DIFF(MAX(event),MIN(event),SECOND)/60.0,1440) approximate_usage_in_minutes
FROM ${events.SQL_TABLE_NAME} WHERE event>=TIMESTAMP_SUB(CURRENT_TIMESTAMP(),INTERVAL 60 DAY)
GROUP BY 1,2,3,4 ;;
 }
  dimension: player_key { type: string  sql: ${TABLE}.player_key ;; }
  dimension: user_id { type: string  sql: ${TABLE}.user_id ;; }
  dimension: game_name { type: string  sql: ${TABLE}.game_name ;; }
  dimension: player_level { type: number  sql: ${TABLE}.player_level ;; }
  dimension: approximate_usage_in_minutes { type: number  sql: ${TABLE}.approximate_usage_in_minutes ;; }
  dimension: level_key { type: string primary_key: yes hidden: yes sql: TO_HEX(SHA256(TO_JSON_STRING(STRUCT(${player_key},${player_level})))) ;; }
  measure: number_of_users { type: count_distinct sql: ${player_key} ;;  }
  measure: average_minutes_at_level { type: average sql: ${approximate_usage_in_minutes} ;;  }

}
