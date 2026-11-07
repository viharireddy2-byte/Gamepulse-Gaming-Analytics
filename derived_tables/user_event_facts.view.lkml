view: lifetime_user_facts {
 derived_table: {
datagroup_trigger: events_raw
sql: SELECT player_key,user_id,game_name,MIN(event) first_seen, MAX(event) latest_seen,
 MIN(IF(event_name='Match_Started',event,NULL)) first_match_started, MAX(IF(event_name='Match_Started',event,NULL)) latest_match_started, COUNTIF(event_name='Match_Started') lifetime_match_started,
 MIN(IF(event_name='Match_Ended',event,NULL)) first_match_ended, MAX(IF(event_name='Match_Ended',event,NULL)) latest_match_ended, COUNTIF(event_name='Match_Ended') lifetime_match_ended,
 MIN(IF(event_name='Ad_Watched',event,NULL)) first_ad_watched, MAX(IF(event_name='Ad_Watched',event,NULL)) latest_ad_watched, COUNTIF(event_name='Ad_Watched') lifetime_ad_watched,
 MIN(IF(event_name='Level_Up',event,NULL)) first_level_up, MAX(IF(event_name='Level_Up',event,NULL)) latest_level_up, COUNTIF(event_name='Level_Up') lifetime_level_up,
 MIN(IF(event_name='Session_Started',event,NULL)) first_session_started, MAX(IF(event_name='Session_Started',event,NULL)) latest_session_started, COUNTIF(event_name='Session_Started') lifetime_session_started,
 MIN(IF(event_name='FTUE_Stage_Complete',event,NULL)) first_ftue_stage_complete, MAX(IF(event_name='FTUE_Stage_Complete',event,NULL)) latest_ftue_stage_complete, COUNTIF(event_name='FTUE_Stage_Complete') lifetime_ftue_stage_complete,
 MIN(IF(event_name='Gem_Spend',event,NULL)) first_gem_spend, MAX(IF(event_name='Gem_Spend',event,NULL)) latest_gem_spend, COUNTIF(event_name='Gem_Spend') lifetime_gem_spend,
 MIN(IF(event_name='FTUE_Stage_Started',event,NULL)) first_ftue_stage_started, MAX(IF(event_name='FTUE_Stage_Started',event,NULL)) latest_ftue_stage_started, COUNTIF(event_name='FTUE_Stage_Started') lifetime_ftue_stage_started,
 MIN(IF(event_name='IAP_Started',event,NULL)) first_iap_started, MAX(IF(event_name='IAP_Started',event,NULL)) latest_iap_started, COUNTIF(event_name='IAP_Started') lifetime_iap_started,
 MIN(IF(event_name='Skin_Unlocked',event,NULL)) first_skin_unlocked, MAX(IF(event_name='Skin_Unlocked',event,NULL)) latest_skin_unlocked, COUNTIF(event_name='Skin_Unlocked') lifetime_skin_unlocked,
 MIN(IF(event_name='Harvest_Done',event,NULL)) first_harvest_done, MAX(IF(event_name='Harvest_Done',event,NULL)) latest_harvest_done, COUNTIF(event_name='Harvest_Done') lifetime_harvest_done,
 MIN(IF(event_name='in_app_purchase',event,NULL)) first_in_app_purchase, MAX(IF(event_name='in_app_purchase',event,NULL)) latest_in_app_purchase, COUNTIF(event_name='in_app_purchase') lifetime_in_app_purchase FROM ${events.SQL_TABLE_NAME} GROUP BY 1,2,3 ;;
 }
  dimension: player_key { type: string primary_key: yes sql: ${TABLE}.player_key ;; }
  dimension: user_id { type: string  sql: ${TABLE}.user_id ;; }
  dimension: game_name { type: string  sql: ${TABLE}.game_name ;; }
  dimension_group: first_seen { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_seen ;; }
  dimension_group: latest_seen { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_seen ;; }
  dimension_group: first_match_started { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_match_started ;; }
  dimension_group: latest_match_started { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_match_started ;; }
  dimension: lifetime_match_started { type: number  sql: ${TABLE}.lifetime_match_started ;; }
  dimension_group: first_match_ended { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_match_ended ;; }
  dimension_group: latest_match_ended { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_match_ended ;; }
  dimension: lifetime_match_ended { type: number  sql: ${TABLE}.lifetime_match_ended ;; }
  dimension_group: first_ad_watched { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_ad_watched ;; }
  dimension_group: latest_ad_watched { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_ad_watched ;; }
  dimension: lifetime_ad_watched { type: number  sql: ${TABLE}.lifetime_ad_watched ;; }
  dimension_group: first_level_up { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_level_up ;; }
  dimension_group: latest_level_up { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_level_up ;; }
  dimension: lifetime_level_up { type: number  sql: ${TABLE}.lifetime_level_up ;; }
  dimension_group: first_session_started { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_session_started ;; }
  dimension_group: latest_session_started { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_session_started ;; }
  dimension: lifetime_session_started { type: number  sql: ${TABLE}.lifetime_session_started ;; }
  dimension_group: first_ftue_stage_complete { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_ftue_stage_complete ;; }
  dimension_group: latest_ftue_stage_complete { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_ftue_stage_complete ;; }
  dimension: lifetime_ftue_stage_complete { type: number  sql: ${TABLE}.lifetime_ftue_stage_complete ;; }
  dimension_group: first_gem_spend { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_gem_spend ;; }
  dimension_group: latest_gem_spend { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_gem_spend ;; }
  dimension: lifetime_gem_spend { type: number  sql: ${TABLE}.lifetime_gem_spend ;; }
  dimension_group: first_ftue_stage_started { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_ftue_stage_started ;; }
  dimension_group: latest_ftue_stage_started { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_ftue_stage_started ;; }
  dimension: lifetime_ftue_stage_started { type: number  sql: ${TABLE}.lifetime_ftue_stage_started ;; }
  dimension_group: first_iap_started { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_iap_started ;; }
  dimension_group: latest_iap_started { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_iap_started ;; }
  dimension: lifetime_iap_started { type: number  sql: ${TABLE}.lifetime_iap_started ;; }
  dimension_group: first_skin_unlocked { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_skin_unlocked ;; }
  dimension_group: latest_skin_unlocked { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_skin_unlocked ;; }
  dimension: lifetime_skin_unlocked { type: number  sql: ${TABLE}.lifetime_skin_unlocked ;; }
  dimension_group: first_harvest_done { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_harvest_done ;; }
  dimension_group: latest_harvest_done { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_harvest_done ;; }
  dimension: lifetime_harvest_done { type: number  sql: ${TABLE}.lifetime_harvest_done ;; }
  dimension_group: first_in_app_purchase { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.first_in_app_purchase ;; }
  dimension_group: latest_in_app_purchase { type: time convert_tz: no timeframes: [raw, time, date, week, month] sql: ${TABLE}.latest_in_app_purchase ;; }
  dimension: lifetime_in_app_purchase { type: number  sql: ${TABLE}.lifetime_in_app_purchase ;; }


parameter: first_date { type: unquoted default_value: "first_seen"
allowed_value: { label: "First Seen" value: "first_seen" }
allowed_value: { label: "Latest Seen" value: "latest_seen" }
allowed_value: { label: "First Match Started" value: "first_match_started" }
allowed_value: { label: "Latest Match Started" value: "latest_match_started" }
allowed_value: { label: "First Match Ended" value: "first_match_ended" }
allowed_value: { label: "Latest Match Ended" value: "latest_match_ended" }
allowed_value: { label: "First Ad Watched" value: "first_ad_watched" }
allowed_value: { label: "Latest Ad Watched" value: "latest_ad_watched" }
allowed_value: { label: "First Level Up" value: "first_level_up" }
allowed_value: { label: "Latest Level Up" value: "latest_level_up" }
allowed_value: { label: "First Session Started" value: "first_session_started" }
allowed_value: { label: "Latest Session Started" value: "latest_session_started" }
allowed_value: { label: "First Ftue Stage Complete" value: "first_ftue_stage_complete" }
allowed_value: { label: "Latest Ftue Stage Complete" value: "latest_ftue_stage_complete" }
allowed_value: { label: "First Gem Spend" value: "first_gem_spend" }
allowed_value: { label: "Latest Gem Spend" value: "latest_gem_spend" }
allowed_value: { label: "First Ftue Stage Started" value: "first_ftue_stage_started" }
allowed_value: { label: "Latest Ftue Stage Started" value: "latest_ftue_stage_started" }
allowed_value: { label: "First Iap Started" value: "first_iap_started" }
allowed_value: { label: "Latest Iap Started" value: "latest_iap_started" }
allowed_value: { label: "First Skin Unlocked" value: "first_skin_unlocked" }
allowed_value: { label: "Latest Skin Unlocked" value: "latest_skin_unlocked" }
allowed_value: { label: "First Harvest Done" value: "first_harvest_done" }
allowed_value: { label: "Latest Harvest Done" value: "latest_harvest_done" }
allowed_value: { label: "First In App Purchase" value: "first_in_app_purchase" }
allowed_value: { label: "Latest In App Purchase" value: "latest_in_app_purchase" }
}

parameter: second_date { type: unquoted default_value: "latest_seen"
allowed_value: { label: "First Seen" value: "first_seen" }
allowed_value: { label: "Latest Seen" value: "latest_seen" }
allowed_value: { label: "First Match Started" value: "first_match_started" }
allowed_value: { label: "Latest Match Started" value: "latest_match_started" }
allowed_value: { label: "First Match Ended" value: "first_match_ended" }
allowed_value: { label: "Latest Match Ended" value: "latest_match_ended" }
allowed_value: { label: "First Ad Watched" value: "first_ad_watched" }
allowed_value: { label: "Latest Ad Watched" value: "latest_ad_watched" }
allowed_value: { label: "First Level Up" value: "first_level_up" }
allowed_value: { label: "Latest Level Up" value: "latest_level_up" }
allowed_value: { label: "First Session Started" value: "first_session_started" }
allowed_value: { label: "Latest Session Started" value: "latest_session_started" }
allowed_value: { label: "First Ftue Stage Complete" value: "first_ftue_stage_complete" }
allowed_value: { label: "Latest Ftue Stage Complete" value: "latest_ftue_stage_complete" }
allowed_value: { label: "First Gem Spend" value: "first_gem_spend" }
allowed_value: { label: "Latest Gem Spend" value: "latest_gem_spend" }
allowed_value: { label: "First Ftue Stage Started" value: "first_ftue_stage_started" }
allowed_value: { label: "Latest Ftue Stage Started" value: "latest_ftue_stage_started" }
allowed_value: { label: "First Iap Started" value: "first_iap_started" }
allowed_value: { label: "Latest Iap Started" value: "latest_iap_started" }
allowed_value: { label: "First Skin Unlocked" value: "first_skin_unlocked" }
allowed_value: { label: "Latest Skin Unlocked" value: "latest_skin_unlocked" }
allowed_value: { label: "First Harvest Done" value: "first_harvest_done" }
allowed_value: { label: "Latest Harvest Done" value: "latest_harvest_done" }
allowed_value: { label: "First In App Purchase" value: "first_in_app_purchase" }
allowed_value: { label: "Latest In App Purchase" value: "latest_in_app_purchase" }
}

dimension_group: event_comparison { type: duration intervals: [second,minute,hour,day] sql_start: ${TABLE}.{% parameter first_date %} ;; sql_end: ${TABLE}.{% parameter second_date %} ;; }

}
