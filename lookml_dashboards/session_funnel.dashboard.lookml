- dashboard: session_funnel
  title: GamePulse | Session Conversion Funnel
  layout: newspaper
  preferred_viewer: dashboards-next
  filters:
  - name: Date
    title: Date
    type: field_filter
    default_value: 30 days
    model: gamepulse
    explore: funnel_explorer
    field: funnel_explorer.event_time
    allow_multiple_values: true
    required: true
  - name: Game
    title: Game
    type: field_filter
    model: gamepulse
    explore: funnel_explorer
    field: funnel_explorer.game_name_filter
    allow_multiple_values: true
    required: false
  elements:
  - name: session_funnel_0
    title: Step 1
    model: gamepulse
    explore: funnel_explorer
    type: single_value
    fields:
    - funnel_explorer.sessions_step_1
    listen:
      Date: funnel_explorer.event_time
      Game: funnel_explorer.game_name_filter
    row: 0
    col: 0
    width: 8
    height: 4
  - name: session_funnel_1
    title: Step 2
    model: gamepulse
    explore: funnel_explorer
    type: single_value
    fields:
    - funnel_explorer.sessions_step_2
    listen:
      Date: funnel_explorer.event_time
      Game: funnel_explorer.game_name_filter
    row: 0
    col: 8
    width: 8
    height: 4
  - name: session_funnel_2
    title: Step 3
    model: gamepulse
    explore: funnel_explorer
    type: single_value
    fields:
    - funnel_explorer.sessions_step_3
    listen:
      Date: funnel_explorer.event_time
      Game: funnel_explorer.game_name_filter
    row: 0
    col: 16
    width: 8
    height: 4
  - name: session_funnel_3
    title: Step 4
    model: gamepulse
    explore: funnel_explorer
    type: single_value
    fields:
    - funnel_explorer.sessions_step_4
    listen:
      Date: funnel_explorer.event_time
      Game: funnel_explorer.game_name_filter
    row: 4
    col: 0
    width: 8
    height: 4
  - name: session_funnel_4
    title: Completion
    model: gamepulse
    explore: funnel_explorer
    type: single_value
    fields:
    - funnel_explorer.completion_rate
    listen:
      Date: funnel_explorer.event_time
      Game: funnel_explorer.game_name_filter
    row: 4
    col: 8
    width: 8
    height: 4
  - name: session_funnel_detail
    title: Game comparison
    model: gamepulse
    explore: funnel_explorer
    type: looker_grid
    fields:
    - funnel_explorer.game_name
    - funnel_explorer.sessions_step_1
    - funnel_explorer.sessions_step_2
    - funnel_explorer.sessions_step_3
    - funnel_explorer.sessions_step_4
    - funnel_explorer.completion_rate
    listen:
      Date: funnel_explorer.event_time
      Game: funnel_explorer.game_name_filter
    row: 8
    col: 0
    width: 24
    height: 8
    limit: 500
