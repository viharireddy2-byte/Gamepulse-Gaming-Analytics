view: funnel_explorer {
 derived_table: {
sql: WITH base AS (
 SELECT * FROM ${events.SQL_TABLE_NAME}
 WHERE {% condition event_time %} event {% endcondition %}
 AND {% condition game_name_filter %} game_name {% endcondition %}
), stage1 AS (
 SELECT unique_session_id,player_key,user_id,game_name, MIN(event) session_start,
 MIN(IF(event_name={% parameter step_1 %},event,NULL)) step1 FROM base GROUP BY 1,2,3,4
), stage2 AS (
 SELECT s.*, MIN(IF(b.event_name={% parameter step_2 %} AND b.event>s.step1,b.event,NULL)) step2
 FROM stage1 s LEFT JOIN base b USING(unique_session_id) GROUP BY ALL
), stage3 AS (
 SELECT s.*, MIN(IF(b.event_name={% parameter step_3 %} AND b.event>s.step2,b.event,NULL)) step3
 FROM stage2 s LEFT JOIN base b USING(unique_session_id) GROUP BY ALL
), stage4 AS (
 SELECT s.*, MIN(IF(b.event_name={% parameter step_4 %} AND b.event>s.step3,b.event,NULL)) step4
 FROM stage3 s LEFT JOIN base b USING(unique_session_id) GROUP BY ALL
) SELECT * FROM stage4 ;;
 }
  dimension: unique_session_id { type: string primary_key: yes sql: ${TABLE}.unique_session_id ;; }
  dimension: player_key { type: string  sql: ${TABLE}.player_key ;; }
  dimension: user_id { type: string  sql: ${TABLE}.user_id ;; }
  dimension: game_name { type: string  sql: ${TABLE}.game_name ;; }
  dimension_group: session_start { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.session_start ;; }
filter: event_time { type: date_time default_value: "30 days" }
filter: game_name_filter { type: string }
parameter: step_1 { type: string default_value: "Session_Started" suggest_explore: events suggest_dimension: events.event_name }
  dimension_group: step1 { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.step1 ;; }
  measure: sessions_step_1 { type: count_distinct sql: IF(${step1_raw} IS NOT NULL,${unique_session_id},NULL) ;;  }
parameter: step_2 { type: string default_value: "FTUE_Stage_Started" suggest_explore: events suggest_dimension: events.event_name }
  dimension_group: step2 { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.step2 ;; }
  measure: sessions_step_2 { type: count_distinct sql: IF(${step2_raw} IS NOT NULL,${unique_session_id},NULL) ;;  }
parameter: step_3 { type: string default_value: "FTUE_Stage_Complete" suggest_explore: events suggest_dimension: events.event_name }
  dimension_group: step3 { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.step3 ;; }
  measure: sessions_step_3 { type: count_distinct sql: IF(${step3_raw} IS NOT NULL,${unique_session_id},NULL) ;;  }
parameter: step_4 { type: string default_value: "in_app_purchase" suggest_explore: events suggest_dimension: events.event_name }
  dimension_group: step4 { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.step4 ;; }
  measure: sessions_step_4 { type: count_distinct sql: IF(${step4_raw} IS NOT NULL,${unique_session_id},NULL) ;;  }
  measure: completion_rate { type: number sql: SAFE_DIVIDE(${sessions_step_4},${sessions_step_1}) ;; value_format_name: percent_2 }

}
