- dashboard: daily_pulse
  title: GamePulse | Player Engagement & Retention
  layout: newspaper
  preferred_viewer: dashboards-next
  filters:
  - name: Date
    title: Date
    type: field_filter
    default_value: 30 days
    model: gamepulse
    explore: events
    field: events.event_date
    allow_multiple_values: true
    required: true
  - name: Game
    title: Game
    type: field_filter
    model: gamepulse
    explore: events
    field: events.game_name
    allow_multiple_values: true
    required: false
  elements:
  - name: daily_pulse_0
    title: Active players
    model: gamepulse
    explore: events
    type: single_value
    fields:
    - events.active_users
    listen:
      Date: events.event_date
      Game: events.game_name
    row: 0
    col: 0
    width: 8
    height: 4
  - name: daily_pulse_1
    title: Revenue
    model: gamepulse
    explore: events
    type: single_value
    fields:
    - events.total_revenue
    listen:
      Date: events.event_date
      Game: events.game_name
    row: 0
    col: 8
    width: 8
    height: 4
  - name: daily_pulse_2
    title: Sessions
    model: gamepulse
    explore: events
    type: single_value
    fields:
    - events.number_of_sessions
    listen:
      Date: events.event_date
      Game: events.game_name
    row: 0
    col: 16
    width: 8
    height: 4
  - name: daily_pulse_detail
    title: Daily trend
    model: gamepulse
    explore: events
    type: looker_grid
    fields:
    - events.event_date
    - events.active_users
    - events.total_revenue
    - events.number_of_sessions
    listen:
      Date: events.event_date
      Game: events.game_name
    row: 8
    col: 0
    width: 24
    height: 8
    limit: 500
