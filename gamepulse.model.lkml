connection: "gamepulse_bigquery"
label: "GamePulse Gaming Analytics"
include: "/views/*.view.lkml"
include: "/derived_tables/*.view.lkml"
include: "/lookml_dashboards/*.dashboard.lookml"
datagroup: events_raw {
 sql_trigger: SELECT CAST(MAX(published_at) AS STRING) FROM `gamepulse.pipeline_state` WHERE status = 'complete' ;;
 max_cache_age: "24 hours"
}
persist_with: events_raw

explore: events {
 always_filter: { filters: [events.event_date: "7 days"] }
 join: user_facts { relationship: many_to_one sql_on: ${events.player_key} = ${user_facts.player_key} ;; }
 join: session_facts { relationship: many_to_one sql_on: ${events.unique_session_id} = ${session_facts.unique_session_id} ;; }
}

explore: session_facts {
 join: user_facts { relationship: many_to_one sql_on: ${session_facts.player_key} = ${user_facts.player_key} ;; }
}

explore: user_facts {
}

explore: funnel_explorer {
 join: user_facts { relationship: many_to_one sql_on: ${funnel_explorer.player_key} = ${user_facts.player_key} ;; }
 join: session_facts { relationship: many_to_one sql_on: ${funnel_explorer.unique_session_id} = ${session_facts.unique_session_id} ;; }
}

explore: level_balancing {
 join: user_facts { relationship: many_to_one sql_on: ${level_balancing.player_key} = ${user_facts.player_key} ;; }
}

explore: top_countries {
}

explore: lifetime_user_facts {
}

# Additive business intelligence modules

explore: retention_cohorts { label: "Retention Cohorts" }

explore: campaign_performance { label: "Campaign Performance" }

explore: monetization_segments { label: "Monetization Segments" }

explore: funnel_diagnostics {
 label: "Funnel Conversion & Timing"
 join: user_facts { relationship: many_to_one sql_on: ${funnel_diagnostics.player_key} = ${user_facts.player_key} ;; }
 join: session_facts { relationship: many_to_one sql_on: ${funnel_diagnostics.unique_session_id} = ${session_facts.unique_session_id} ;; }
}
