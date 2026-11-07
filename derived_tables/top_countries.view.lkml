view: top_countries {
 derived_table: {
datagroup_trigger: events_raw
sql: SELECT country,SUM(COALESCE(iap_revenue,0)+COALESCE(ad_revenue,0)) total_revenue, DENSE_RANK() OVER(ORDER BY SUM(COALESCE(iap_revenue,0)+COALESCE(ad_revenue,0)) DESC) country_rank FROM ${events.SQL_TABLE_NAME} GROUP BY country ;;
 }
  dimension: country { type: string primary_key: yes sql: ${TABLE}.country ;; }
  dimension: country_rank { type: number  sql: ${TABLE}.country_rank ;; }
  dimension: is_top_10_country { type: yesno  sql: ${country_rank}<=10 ;; }
  measure: total_revenue { type: sum sql: ${TABLE}.total_revenue ;;  }

}
