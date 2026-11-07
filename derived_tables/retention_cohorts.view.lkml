view: retention_cohorts {
 derived_table: { datagroup_trigger: events_raw
 sql: WITH players AS (
 SELECT player_key,user_id,game_name,DATE(player_first_seen) cohort,
 COALESCE(install_source,'Unknown') install_source,COALESCE(campaign_name,'Unknown') campaign_name,
 COALESCE(most_commonly_used_device,'Unknown') device_platform FROM ${user_facts.SQL_TABLE_NAME}
), activity AS (
 SELECT DISTINCT player_key,DATE(event) activity_date FROM ${events.SQL_TABLE_NAME}
), daily AS (
 SELECT p.*,age_day,
 DATE_DIFF(CURRENT_DATE(),cohort,DAY)>age_day eligible,
 a.player_key IS NOT NULL returned
 FROM players p CROSS JOIN UNNEST(GENERATE_ARRAY(0,30)) age_day
 LEFT JOIN activity a ON p.player_key=a.player_key AND a.activity_date=DATE_ADD(p.cohort,INTERVAL age_day DAY)
)
SELECT game_name,cohort,install_source,campaign_name,device_platform,age_day,
 TO_HEX(SHA256(TO_JSON_STRING(STRUCT(game_name,cohort,install_source,campaign_name,device_platform,age_day)))) cohort_cell_key,
 COUNT(*) cohort_players,COUNTIF(eligible) eligible_players,COUNTIF(eligible AND returned) retained_players
FROM daily GROUP BY 1,2,3,4,5,6 ;;
 }

dimension: cohort_cell_key { type: string primary_key: yes hidden: yes sql: ${TABLE}.cohort_cell_key ;; }
dimension: game_name { type: string  sql: ${TABLE}.game_name ;; }
dimension: install_source { type: string  sql: ${TABLE}.install_source ;; }
dimension: campaign_name { type: string  sql: ${TABLE}.campaign_name ;; }
dimension: device_platform { type: string  sql: ${TABLE}.device_platform ;; }
dimension_group: cohort { type: time convert_tz: no timeframes: [raw,date,week,month] sql: ${TABLE}.cohort ;; }
dimension: age_day { type: number  sql: ${TABLE}.age_day ;; }
measure: cohort_players { type: sum sql: ${TABLE}.cohort_players ;;  }
measure: eligible_players { type: sum sql: ${TABLE}.eligible_players ;;  }
measure: retained_players { type: sum sql: ${TABLE}.retained_players ;;  }
measure: retention_rate { type: number sql: SAFE_DIVIDE(${retained_players},${eligible_players}) ;; value_format_name: percent_2 }
measure: cohort_size { type: max sql: ${TABLE}.cohort_players ;; description: "Cell size; select a single cohort/segment or use eligible_players at one age. Do not sum players across ages." }
}
