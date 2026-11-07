view: user_facts {
 derived_table: {
datagroup_trigger: events_raw
sql: WITH player AS (
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
 FROM ${events.SQL_TABLE_NAME} GROUP BY 1,2,3
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
FROM player p JOIN ${events.SQL_TABLE_NAME} e USING(player_key)
LEFT JOIN (SELECT player_key,SUM(session_length_minutes) total_session_length FROM ${session_facts.SQL_TABLE_NAME} GROUP BY 1) s USING(player_key)
GROUP BY ALL ;;
 }
  dimension: player_key { type: string primary_key: yes sql: ${TABLE}.player_key ;; }
  dimension: user_id { type: string  sql: ${TABLE}.user_id ;; }
  dimension: game_name { type: string  sql: ${TABLE}.game_name ;; }
  dimension: install_source { type: string  sql: ${TABLE}.install_source ;; }
  dimension: campaign_name { type: string  sql: ${TABLE}.campaign_name ;; }
  dimension_group: player_first_seen { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.player_first_seen ;; }
  dimension_group: player_last_seen { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.player_last_seen ;; }
  dimension: days_played { type: number  sql: ${TABLE}.days_played ;; }
  dimension: number_of_sessions { type: number  sql: ${TABLE}.number_of_sessions ;; }
  dimension: lifetime_iap_revenue { type: number  sql: ${TABLE}.lifetime_iap_revenue ;; }
  dimension: lifetime_ad_revenue { type: number  sql: ${TABLE}.lifetime_ad_revenue ;; }
  dimension: lifetime_revenue { type: number  sql: ${TABLE}.lifetime_revenue ;; }
  dimension: install_cost { type: number  sql: ${TABLE}.install_cost ;; }
  dimension: highest_level_reached { type: number  sql: ${TABLE}.highest_level_reached ;; }
  dimension: player_segment { type: string  sql: CASE WHEN ${lifetime_iap_revenue}>=100 THEN 'High value' WHEN ${lifetime_iap_revenue}>0 THEN 'Payer' ELSE 'Non-payer' END ;; }
  dimension: is_churned { type: yesno  sql: DATE_DIFF(CURRENT_DATE(),${player_last_seen_date},DAY)>7 ;; }
  measure: number_of_users { type: count sql: 1 ;;  }
  measure: total_revenue { type: sum sql: ${lifetime_revenue} ;;  }
  measure: acquisition_cost { type: sum sql: ${install_cost} ;;  }
  measure: roas { type: number sql: SAFE_DIVIDE(${total_revenue},${acquisition_cost}) ;; value_format_name: percent_2 }
  measure: revenue_after_acquisition { type: number sql: ${total_revenue}-${acquisition_cost} ;;  }
  dimension: d1_retained { type: yesno  sql: ${TABLE}.d1_retained ;; }
  measure: d1_eligible_users { type: count_distinct sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>1,${player_key},NULL) ;;  }
  measure: d1_retained_users { type: count_distinct sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>1 AND ${d1_retained},${player_key},NULL) ;;  }
  measure: d1_retention_rate { type: number sql: SAFE_DIVIDE(${d1_retained_users},${d1_eligible_users}) ;; value_format_name: percent_2 }
  dimension: d7_retained { type: yesno  sql: ${TABLE}.d7_retained ;; }
  measure: d7_eligible_users { type: count_distinct sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>7,${player_key},NULL) ;;  }
  measure: d7_retained_users { type: count_distinct sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>7 AND ${d7_retained},${player_key},NULL) ;;  }
  measure: d7_retention_rate { type: number sql: SAFE_DIVIDE(${d7_retained_users},${d7_eligible_users}) ;; value_format_name: percent_2 }
  dimension: d14_retained { type: yesno  sql: ${TABLE}.d14_retained ;; }
  measure: d14_eligible_users { type: count_distinct sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>14,${player_key},NULL) ;;  }
  measure: d14_retained_users { type: count_distinct sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>14 AND ${d14_retained},${player_key},NULL) ;;  }
  measure: d14_retention_rate { type: number sql: SAFE_DIVIDE(${d14_retained_users},${d14_eligible_users}) ;; value_format_name: percent_2 }
  dimension: d30_retained { type: yesno  sql: ${TABLE}.d30_retained ;; }
  measure: d30_eligible_users { type: count_distinct sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>30,${player_key},NULL) ;;  }
  measure: d30_retained_users { type: count_distinct sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>30 AND ${d30_retained},${player_key},NULL) ;;  }
  measure: d30_retention_rate { type: number sql: SAFE_DIVIDE(${d30_retained_users},${d30_eligible_users}) ;; value_format_name: percent_2 }


dimension: lifetime_level_ups { type: number sql: ${TABLE}.lifetime_level_ups ;; }
dimension: number_of_devices_used { type: number sql: ${TABLE}.number_of_devices_used ;; }
dimension: number_of_countries_played_in { type: number sql: ${TABLE}.number_of_countries_played_in ;; }
dimension: most_commonly_used_device { type: string sql: ${TABLE}.most_commonly_used_device ;; }
dimension: most_commonly_played_country { type: string sql: ${TABLE}.most_commonly_played_country ;; }
measure: total_iap_revenue { type: sum sql: ${lifetime_iap_revenue} ;; }
measure: total_ad_revenue { type: sum sql: ${lifetime_ad_revenue} ;; }
measure: median_days_played { type: median sql: ${days_played} ;; }
dimension: is_roas_positive { type: yesno sql: ${lifetime_revenue}>${install_cost} ;; }
measure: paid_users { type: count_distinct sql: IF(${install_cost}>0,${player_key},NULL) ;; }
measure: roas_positive_paid_users { type: count_distinct sql: IF(${install_cost}>0 AND ${is_roas_positive},${player_key},NULL) ;; }
measure: percent_roas_positive { type: number sql: SAFE_DIVIDE(${roas_positive_paid_users},${paid_users}) ;; }
dimension: total_d1_revenue { type: number sql: ${TABLE}.total_d1_revenue ;; }
measure: mature_d1_revenue { type: sum sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>1,${total_d1_revenue},NULL) ;; }
measure: mature_d1_spend { type: sum sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>1,${install_cost},NULL) ;; }
measure: d1_roas { type: number sql: SAFE_DIVIDE(${mature_d1_revenue},${mature_d1_spend}) ;; }
parameter: d1_roas_target { type: number default_value: "0.0333" }

measure: d1_roas_target_attainment { type: number sql: SAFE_DIVIDE(${d1_roas},{% parameter d1_roas_target %}) ;; }
dimension: total_d7_revenue { type: number sql: ${TABLE}.total_d7_revenue ;; }
measure: mature_d7_revenue { type: sum sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>7,${total_d7_revenue},NULL) ;; }
measure: mature_d7_spend { type: sum sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>7,${install_cost},NULL) ;; }
measure: d7_roas { type: number sql: SAFE_DIVIDE(${mature_d7_revenue},${mature_d7_spend}) ;; }
parameter: d7_roas_target { type: number default_value: "0.2333" }

measure: d7_roas_target_attainment { type: number sql: SAFE_DIVIDE(${d7_roas},{% parameter d7_roas_target %}) ;; }
dimension: total_d14_revenue { type: number sql: ${TABLE}.total_d14_revenue ;; }
measure: mature_d14_revenue { type: sum sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>14,${total_d14_revenue},NULL) ;; }
measure: mature_d14_spend { type: sum sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>14,${install_cost},NULL) ;; }
measure: d14_roas { type: number sql: SAFE_DIVIDE(${mature_d14_revenue},${mature_d14_spend}) ;; }
parameter: d14_roas_target { type: number default_value: "0.4667" }

measure: d14_roas_target_attainment { type: number sql: SAFE_DIVIDE(${d14_roas},{% parameter d14_roas_target %}) ;; }
dimension: total_d30_revenue { type: number sql: ${TABLE}.total_d30_revenue ;; }
measure: mature_d30_revenue { type: sum sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>30,${total_d30_revenue},NULL) ;; }
measure: mature_d30_spend { type: sum sql: IF(DATE_DIFF(CURRENT_DATE(),${player_first_seen_date},DAY)>30,${install_cost},NULL) ;; }
measure: d30_roas { type: number sql: SAFE_DIVIDE(${mature_d30_revenue},${mature_d30_spend}) ;; }
parameter: d30_roas_target { type: number default_value: "1.0000" }

measure: d30_roas_target_attainment { type: number sql: SAFE_DIVIDE(${d30_roas},{% parameter d30_roas_target %}) ;; }
measure: min_highest_level_reached { type: min sql: ${highest_level_reached} ;; }
measure: max_highest_level_reached { type: max sql: ${highest_level_reached} ;; }
measure: median_highest_level_reached { type: median sql: ${highest_level_reached} ;; }

dimension: total_session_length { type: number sql: ${TABLE}.total_session_length ;; }
}
