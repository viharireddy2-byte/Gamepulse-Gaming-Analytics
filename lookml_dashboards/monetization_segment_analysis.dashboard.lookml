- dashboard: monetization_segment_analysis
  title: GamePulse | Monetization & Revenue Concentration
  layout: newspaper
  preferred_viewer: dashboards-next
  filters:
  - name: Cohort date
    title: Cohort date
    type: field_filter
    default_value: 90 days
    model: gamepulse
    explore: monetization_segments
    field: monetization_segments.cohort_date
    allow_multiple_values: true
    required: true
  - name: Game
    title: Game
    type: field_filter
    default_value: ''
    model: gamepulse
    explore: monetization_segments
    field: monetization_segments.game_name
    allow_multiple_values: true
    required: false
  - name: Channel
    title: Channel
    type: field_filter
    default_value: ''
    model: gamepulse
    explore: monetization_segments
    field: monetization_segments.install_source
    allow_multiple_values: true
    required: false
  - name: Platform
    title: Platform
    type: field_filter
    default_value: ''
    model: gamepulse
    explore: monetization_segments
    field: monetization_segments.device_platform
    allow_multiple_values: true
    required: false
  elements:
  - name: monetization_segment_analysis_0
    title: Lifetime payer conversion
    model: gamepulse
    explore: monetization_segments
    type: single_value
    fields:
    - monetization_segments.payer_conversion
    listen: &id001
      Cohort date: monetization_segments.cohort_date
      Game: monetization_segments.game_name
      Channel: monetization_segments.install_source
      Platform: monetization_segments.device_platform
    row: 0
    col: 0
    width: 8
    height: 4
    limit: 500
  - name: monetization_segment_analysis_1
    title: Lifetime IAP ARPPU
    model: gamepulse
    explore: monetization_segments
    type: single_value
    fields:
    - monetization_segments.arppu
    listen: *id001
    row: 0
    col: 8
    width: 8
    height: 4
    limit: 500
  - name: monetization_segment_analysis_2
    title: Lifetime top-decile revenue share
    model: gamepulse
    explore: monetization_segments
    type: single_value
    fields:
    - monetization_segments.top_decile_revenue_share
    listen: *id001
    row: 0
    col: 16
    width: 8
    height: 4
    limit: 500
  - name: monetization_segment_analysis_3
    title: Revenue mix by value segment
    model: gamepulse
    explore: monetization_segments
    type: looker_column
    fields:
    - monetization_segments.value_segment
    - monetization_segments.iap_revenue
    - monetization_segments.ad_revenue
    listen: *id001
    row: 4
    col: 0
    width: 12
    height: 7
    limit: 500
    stacking: normal
  - name: monetization_segment_analysis_4
    title: Players and revenue by value segment
    model: gamepulse
    explore: monetization_segments
    type: looker_grid
    fields:
    - monetization_segments.value_segment
    - monetization_segments.players
    - monetization_segments.payers
    - monetization_segments.revenue
    - monetization_segments.payer_conversion
    - monetization_segments.arpu
    - monetization_segments.arppu
    listen: *id001
    row: 4
    col: 12
    width: 12
    height: 7
    limit: 500
  - name: monetization_segment_analysis_5
    title: Platform and channel comparisons
    model: gamepulse
    explore: monetization_segments
    type: looker_grid
    fields:
    - monetization_segments.game_name
    - monetization_segments.device_platform
    - monetization_segments.install_source
    - monetization_segments.players
    - monetization_segments.payer_conversion
    - monetization_segments.arppu
    - monetization_segments.top_decile_revenue_share
    listen: *id001
    row: 11
    col: 0
    width: 24
    height: 7
    limit: 500
