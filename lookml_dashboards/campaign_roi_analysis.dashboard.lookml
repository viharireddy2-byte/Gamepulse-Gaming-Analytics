- dashboard: campaign_roi_analysis
  title: GamePulse | Acquisition ROI & Campaign Review
  layout: newspaper
  preferred_viewer: dashboards-next
  filters:
  - name: Cohort date
    title: Cohort date
    type: field_filter
    default_value: 90 days
    model: gamepulse
    explore: campaign_performance
    field: campaign_performance.cohort_date
    allow_multiple_values: true
    required: true
  - name: Game
    title: Game
    type: field_filter
    default_value: ''
    model: gamepulse
    explore: campaign_performance
    field: campaign_performance.game_name
    allow_multiple_values: true
    required: false
  - name: Channel
    title: Channel
    type: field_filter
    default_value: -Organic
    model: gamepulse
    explore: campaign_performance
    field: campaign_performance.install_source
    allow_multiple_values: true
    required: false
  - name: Platform
    title: Platform
    type: field_filter
    default_value: ''
    model: gamepulse
    explore: campaign_performance
    field: campaign_performance.device_platform
    allow_multiple_values: true
    required: false
  elements:
  - name: campaign_roi_analysis_0
    title: Mature D7 ROAS
    model: gamepulse
    explore: campaign_performance
    type: single_value
    fields:
    - campaign_performance.d7_roas
    listen: &id001
      Cohort date: campaign_performance.cohort_date
      Game: campaign_performance.game_name
      Channel: campaign_performance.install_source
      Platform: campaign_performance.device_platform
    row: 0
    col: 0
    width: 8
    height: 4
    limit: 500
  - name: campaign_roi_analysis_1
    title: Mature D30 ROAS
    model: gamepulse
    explore: campaign_performance
    type: single_value
    fields:
    - campaign_performance.d30_roas
    listen: *id001
    row: 0
    col: 8
    width: 8
    height: 4
    limit: 500
  - name: campaign_roi_analysis_2
    title: Spend in selected cohorts
    model: gamepulse
    explore: campaign_performance
    type: single_value
    fields:
    - campaign_performance.acquisition_spend
    listen: *id001
    row: 0
    col: 16
    width: 8
    height: 4
    limit: 500
  - name: campaign_roi_analysis_3
    title: "Campaign review \u2014 target gap and sample guard"
    model: gamepulse
    explore: campaign_performance
    type: looker_grid
    fields:
    - campaign_performance.campaign_name
    - campaign_performance.install_source
    - campaign_performance.d7_mature_players
    - campaign_performance.d7_spend
    - campaign_performance.d7_roas
    - campaign_performance.d7_target_attainment
    - campaign_performance.d7_revenue_gap
    - campaign_performance.d7_review_status
    - campaign_performance.d7_review_priority
    hidden_fields: [campaign_performance.d7_review_priority]
    listen: *id001
    row: 4
    col: 0
    width: 24
    height: 8
    limit: 500
    sorts:
    - campaign_performance.d7_review_priority desc
  - name: campaign_roi_analysis_4
    title: D7 target attainment by campaign
    model: gamepulse
    explore: campaign_performance
    type: looker_bar
    fields:
    - campaign_performance.campaign_name
    - campaign_performance.d7_target_attainment
    listen: *id001
    row: 12
    col: 0
    width: 12
    height: 7
    limit: 500
  - name: campaign_roi_analysis_5
    title: Cohort ROAS maturity curve
    model: gamepulse
    explore: campaign_performance
    type: looker_line
    fields:
    - campaign_performance.cohort_week
    - campaign_performance.d1_roas
    - campaign_performance.d7_roas
    - campaign_performance.d14_roas
    - campaign_performance.d30_roas
    listen: *id001
    row: 12
    col: 12
    width: 12
    height: 7
    limit: 500
    sorts:
    - campaign_performance.cohort_week
