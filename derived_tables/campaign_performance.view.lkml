view: campaign_performance {
 derived_table: { datagroup_trigger: events_raw
 sql: SELECT u.*,COALESCE(most_commonly_used_device,'Unknown') device_platform,
 DATE(player_first_seen) cohort,
 DATE_DIFF(CURRENT_DATE(),DATE(player_first_seen),DAY) cohort_age
FROM ${user_facts.SQL_TABLE_NAME} u ;;
 }

dimension: player_key { type: string primary_key: yes sql: ${TABLE}.player_key ;; }
dimension: user_id { type: string  sql: ${TABLE}.user_id ;; }
dimension: game_name { type: string  sql: ${TABLE}.game_name ;; }
dimension: install_source { type: string  sql: ${TABLE}.install_source ;; }
dimension: campaign_name { type: string  sql: ${TABLE}.campaign_name ;; }
dimension: device_platform { type: string  sql: ${TABLE}.device_platform ;; }
dimension_group: cohort { type: time convert_tz: no timeframes: [raw,date,week,month] sql: ${TABLE}.cohort ;; }
measure: players { type: count_distinct sql: ${player_key} ;;  }
measure: lifetime_revenue { type: sum sql: ${TABLE}.lifetime_revenue ;; value_format_name: usd }
measure: acquisition_spend { type: sum sql: ${TABLE}.install_cost ;; value_format_name: usd }
measure: cpi { type: number sql: SAFE_DIVIDE(${acquisition_spend},${players}) ;; value_format_name: usd }
parameter: minimum_mature_players { type: number default_value: "100" }

measure: d1_mature_players { type: count_distinct sql: IF(${TABLE}.cohort_age>1,${player_key},NULL) ;;  }
measure: d1_revenue { type: sum sql: IF(${TABLE}.cohort_age>1,${TABLE}.total_d1_revenue,NULL) ;; value_format_name: usd }
measure: d1_spend { type: sum sql: IF(${TABLE}.cohort_age>1,${TABLE}.install_cost,NULL) ;; value_format_name: usd }
measure: d1_roas { type: number sql: SAFE_DIVIDE(${d1_revenue},${d1_spend}) ;; value_format_name: percent_2 }
parameter: d1_target { type: number default_value: "0.1" }

measure: d1_target_attainment { type: number sql: SAFE_DIVIDE(${d1_roas},{% parameter d1_target %}) ;; value_format_name: percent_2 }
measure: d1_revenue_gap { type: number sql: (${d1_spend} * {% parameter d1_target %}) - ${d1_revenue} ;; value_format_name: usd }
measure: d7_mature_players { type: count_distinct sql: IF(${TABLE}.cohort_age>7,${player_key},NULL) ;;  }
measure: d7_revenue { type: sum sql: IF(${TABLE}.cohort_age>7,${TABLE}.total_d7_revenue,NULL) ;; value_format_name: usd }
measure: d7_spend { type: sum sql: IF(${TABLE}.cohort_age>7,${TABLE}.install_cost,NULL) ;; value_format_name: usd }
measure: d7_roas { type: number sql: SAFE_DIVIDE(${d7_revenue},${d7_spend}) ;; value_format_name: percent_2 }
parameter: d7_target { type: number default_value: "0.3" }

measure: d7_target_attainment { type: number sql: SAFE_DIVIDE(${d7_roas},{% parameter d7_target %}) ;; value_format_name: percent_2 }
measure: d7_revenue_gap { type: number sql: (${d7_spend} * {% parameter d7_target %}) - ${d7_revenue} ;; value_format_name: usd }
measure: d14_mature_players { type: count_distinct sql: IF(${TABLE}.cohort_age>14,${player_key},NULL) ;;  }
measure: d14_revenue { type: sum sql: IF(${TABLE}.cohort_age>14,${TABLE}.total_d14_revenue,NULL) ;; value_format_name: usd }
measure: d14_spend { type: sum sql: IF(${TABLE}.cohort_age>14,${TABLE}.install_cost,NULL) ;; value_format_name: usd }
measure: d14_roas { type: number sql: SAFE_DIVIDE(${d14_revenue},${d14_spend}) ;; value_format_name: percent_2 }
parameter: d14_target { type: number default_value: "0.6" }

measure: d14_target_attainment { type: number sql: SAFE_DIVIDE(${d14_roas},{% parameter d14_target %}) ;; value_format_name: percent_2 }
measure: d14_revenue_gap { type: number sql: (${d14_spend} * {% parameter d14_target %}) - ${d14_revenue} ;; value_format_name: usd }
measure: d30_mature_players { type: count_distinct sql: IF(${TABLE}.cohort_age>30,${player_key},NULL) ;;  }
measure: d30_revenue { type: sum sql: IF(${TABLE}.cohort_age>30,${TABLE}.total_d30_revenue,NULL) ;; value_format_name: usd }
measure: d30_spend { type: sum sql: IF(${TABLE}.cohort_age>30,${TABLE}.install_cost,NULL) ;; value_format_name: usd }
measure: d30_roas { type: number sql: SAFE_DIVIDE(${d30_revenue},${d30_spend}) ;; value_format_name: percent_2 }
parameter: d30_target { type: number default_value: "1.0" }

measure: d30_target_attainment { type: number sql: SAFE_DIVIDE(${d30_roas},{% parameter d30_target %}) ;; value_format_name: percent_2 }
measure: d30_revenue_gap { type: number sql: (${d30_spend} * {% parameter d30_target %}) - ${d30_revenue} ;; value_format_name: usd }
measure: d7_review_priority { type: number sql: CASE WHEN ${d7_spend} IS NULL OR ${d7_spend}=0 THEN NULL WHEN ${d7_mature_players} < {% parameter minimum_mature_players %} THEN NULL ELSE GREATEST(${d7_revenue_gap},0) END ;; value_format_name: usd }
measure: d7_review_status { type: string sql: CASE WHEN ${d7_spend} IS NULL OR ${d7_spend}=0 THEN 'No paid mature cohort' WHEN ${d7_mature_players} < {% parameter minimum_mature_players %} THEN 'Insufficient sample' WHEN ${d7_roas} < {% parameter d7_target %} THEN 'Investigate below target' ELSE 'At or above target' END ;;  }
}
