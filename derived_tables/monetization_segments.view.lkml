view: monetization_segments {
 derived_table: { datagroup_trigger: events_raw
 sql: SELECT u.*,DATE(player_first_seen) cohort,
 COALESCE(most_commonly_used_device,'Unknown') device_platform,
 CASE WHEN lifetime_iap_revenue>=100 THEN 'High value' WHEN lifetime_iap_revenue>0 THEN 'Payer' ELSE 'Non-payer' END value_segment,
 ROW_NUMBER() OVER(PARTITION BY game_name ORDER BY lifetime_revenue DESC,player_key) revenue_rank,
 COUNT(*) OVER(PARTITION BY game_name) game_players
FROM ${user_facts.SQL_TABLE_NAME} u ;;
 }

dimension: player_key { type: string primary_key: yes sql: ${TABLE}.player_key ;; }
dimension: game_name { type: string  sql: ${TABLE}.game_name ;; }
dimension: install_source { type: string  sql: ${TABLE}.install_source ;; }
dimension: campaign_name { type: string  sql: ${TABLE}.campaign_name ;; }
dimension: device_platform { type: string  sql: ${TABLE}.device_platform ;; }
dimension: value_segment { type: string  sql: ${TABLE}.value_segment ;; }
dimension_group: cohort { type: time convert_tz: no timeframes: [raw,date,week,month] sql: ${TABLE}.cohort ;; }
dimension: is_top_decile { type: yesno  sql: ${TABLE}.revenue_rank<=CEIL(${TABLE}.game_players*0.10) ;; }
measure: players { type: count_distinct sql: ${player_key} ;;  }
measure: payers { type: count_distinct sql: IF(${TABLE}.lifetime_iap_revenue>0,${player_key},NULL) ;;  }
measure: revenue { type: sum sql: ${TABLE}.lifetime_revenue ;; value_format_name: usd }
measure: iap_revenue { type: sum sql: ${TABLE}.lifetime_iap_revenue ;; value_format_name: usd }
measure: ad_revenue { type: sum sql: ${TABLE}.lifetime_ad_revenue ;; value_format_name: usd }
measure: payer_conversion { type: number sql: SAFE_DIVIDE(${payers},${players}) ;; value_format_name: percent_2 }
measure: arpu { type: number sql: SAFE_DIVIDE(${revenue},${players}) ;; value_format_name: usd }
measure: arppu { type: number sql: SAFE_DIVIDE(${iap_revenue},${payers}) ;; value_format_name: usd }
measure: top_decile_revenue { type: sum sql: IF(${is_top_decile},${TABLE}.lifetime_revenue,0) ;; value_format_name: usd }
measure: top_decile_revenue_share { type: number sql: SAFE_DIVIDE(${top_decile_revenue},${revenue}) ;; value_format_name: percent_2 }
}
