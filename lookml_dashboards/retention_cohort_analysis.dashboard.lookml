- dashboard: retention_cohort_analysis
  title: GamePulse | Retention Cohorts
  layout: newspaper
  preferred_viewer: dashboards-next
  filters:
  - name: Cohort date
    title: Cohort date
    type: field_filter
    default_value: 90 days
    model: gamepulse
    explore: retention_cohorts
    field: retention_cohorts.cohort_date
    allow_multiple_values: true
    required: true
  - name: Game
    title: Game
    type: field_filter
    default_value: ''
    model: gamepulse
    explore: retention_cohorts
    field: retention_cohorts.game_name
    allow_multiple_values: true
    required: false
  - name: Channel
    title: Channel
    type: field_filter
    default_value: ''
    model: gamepulse
    explore: retention_cohorts
    field: retention_cohorts.install_source
    allow_multiple_values: true
    required: false
  - name: Platform
    title: Platform
    type: field_filter
    default_value: ''
    model: gamepulse
    explore: retention_cohorts
    field: retention_cohorts.device_platform
    allow_multiple_values: true
    required: false
  elements:
  - name: retention_cohort_analysis_0
    title: "Exact-day retention heatmap \u2014 closed UTC days"
    model: gamepulse
    explore: retention_cohorts
    type: looker_grid
    fields:
    - retention_cohorts.cohort_week
    - retention_cohorts.age_day
    - retention_cohorts.retention_rate
    listen: &id001
      Cohort date: retention_cohorts.cohort_date
      Game: retention_cohorts.game_name
      Channel: retention_cohorts.install_source
      Platform: retention_cohorts.device_platform
    row: 0
    col: 0
    width: 24
    height: 7
    limit: 500
    pivots:
    - retention_cohorts.age_day
    sorts:
    - retention_cohorts.cohort_week desc
    - retention_cohorts.age_day
    filters:
      retention_cohorts.age_day: 1,7,14,30
    enable_conditional_formatting: true
    conditional_formatting:
    - type: greater than or equal to
      value: 0.5
      background_color: '#b8e0d2'
      font_color: '#163b30'
      fields:
      - retention_cohorts.retention_rate
    - type: less than
      value: 0.2
      background_color: '#f5cece'
      font_color: '#642c2c'
      fields:
      - retention_cohorts.retention_rate
  - name: retention_cohort_analysis_1
    title: Retention curve by channel
    model: gamepulse
    explore: retention_cohorts
    type: looker_line
    fields:
    - retention_cohorts.age_day
    - retention_cohorts.install_source
    - retention_cohorts.retention_rate
    listen: *id001
    row: 7
    col: 0
    width: 24
    height: 7
    limit: 500
    pivots:
    - retention_cohorts.install_source
    sorts:
    - retention_cohorts.age_day
    filters:
      retention_cohorts.age_day: 1,7,14,30
  - name: retention_cohort_analysis_2
    title: Cohort sample sizes and platform comparisons
    model: gamepulse
    explore: retention_cohorts
    type: looker_grid
    fields:
    - retention_cohorts.cohort_week
    - retention_cohorts.device_platform
    - retention_cohorts.age_day
    - retention_cohorts.eligible_players
    - retention_cohorts.retained_players
    - retention_cohorts.retention_rate
    listen: *id001
    row: 14
    col: 0
    width: 24
    height: 7
    limit: 500
    sorts:
    - retention_cohorts.cohort_week desc
    filters:
      retention_cohorts.age_day: 1,7,14,30
