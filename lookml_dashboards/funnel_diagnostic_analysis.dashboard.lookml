- dashboard: funnel_diagnostic_analysis
  title: GamePulse | Funnel Abandonment & Conversion Time
  layout: newspaper
  preferred_viewer: dashboards-next
  filters:
  - name: Event date
    title: Event date
    type: field_filter
    default_value: 90 days
    model: gamepulse
    explore: funnel_diagnostics
    field: funnel_diagnostics.event_time
    allow_multiple_values: true
    required: true
  - name: Game
    title: Game
    type: field_filter
    default_value: ''
    model: gamepulse
    explore: funnel_diagnostics
    field: funnel_diagnostics.game_name_filter
    allow_multiple_values: true
    required: false
  - name: Step 1
    title: Step 1
    type: field_filter
    default_value: Session_Started
    model: gamepulse
    explore: funnel_diagnostics
    field: funnel_diagnostics.step_1
    allow_multiple_values: false
    required: true
  - name: Step 2
    title: Step 2
    type: field_filter
    default_value: FTUE_Stage_Started
    model: gamepulse
    explore: funnel_diagnostics
    field: funnel_diagnostics.step_2
    allow_multiple_values: false
    required: true
  - name: Step 3
    title: Step 3
    type: field_filter
    default_value: FTUE_Stage_Complete
    model: gamepulse
    explore: funnel_diagnostics
    field: funnel_diagnostics.step_3
    allow_multiple_values: false
    required: true
  - name: Step 4
    title: Step 4
    type: field_filter
    default_value: in_app_purchase
    model: gamepulse
    explore: funnel_diagnostics
    field: funnel_diagnostics.step_4
    allow_multiple_values: false
    required: true
  elements:
  - name: funnel_diagnostic_analysis_0
    title: Ordered session conversion
    model: gamepulse
    explore: funnel_diagnostics
    type: looker_funnel
    fields:
    - funnel_diagnostics.sessions_step_1
    - funnel_diagnostics.sessions_step_2
    - funnel_diagnostics.sessions_step_3
    - funnel_diagnostics.sessions_step_4
    listen: &id001
      Event date: funnel_diagnostics.event_time
      Game: funnel_diagnostics.game_name_filter
      Step 1: funnel_diagnostics.step_1
      Step 2: funnel_diagnostics.step_2
      Step 3: funnel_diagnostics.step_3
      Step 4: funnel_diagnostics.step_4
    row: 0
    col: 0
    width: 24
    height: 6
    limit: 500
  - name: funnel_diagnostic_analysis_1
    title: Stage continuation and abandonment
    model: gamepulse
    explore: funnel_diagnostics
    type: looker_grid
    fields:
    - funnel_diagnostics.game_name
    - funnel_diagnostics.step_1_continuation
    - funnel_diagnostics.step_2_continuation
    - funnel_diagnostics.step_3_continuation
    - funnel_diagnostics.step_1_dropoffs
    - funnel_diagnostics.step_2_dropoffs
    - funnel_diagnostics.step_3_dropoffs
    listen: *id001
    row: 6
    col: 0
    width: 24
    height: 7
    limit: 500
  - name: funnel_diagnostic_analysis_2
    title: "Median conversion seconds \u2014 converters only"
    model: gamepulse
    explore: funnel_diagnostics
    type: looker_grid
    fields:
    - funnel_diagnostics.game_name
    - funnel_diagnostics.median_seconds_1_to_2
    - funnel_diagnostics.median_seconds_2_to_3
    - funnel_diagnostics.median_seconds_3_to_4
    - funnel_diagnostics.median_seconds_to_complete
    listen: *id001
    row: 13
    col: 0
    width: 24
    height: 7
    limit: 500
