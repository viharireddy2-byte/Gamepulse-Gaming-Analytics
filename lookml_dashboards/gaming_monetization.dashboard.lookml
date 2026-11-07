- dashboard: gaming_monetization
  title: GamePulse | Monetization & Acquisition ROI
  layout: newspaper
  preferred_viewer: dashboards-next
  filters:
  - name: Date
    title: Date
    type: field_filter
    default_value: 30 days
    model: gamepulse
    explore: user_facts
    field: user_facts.player_first_seen_date
    allow_multiple_values: true
    required: true
  - name: Game
    title: Game
    type: field_filter
    model: gamepulse
    explore: user_facts
    field: user_facts.game_name
    allow_multiple_values: true
    required: false
  elements:
  - name: gaming_monetization_0
    title: Lifetime revenue
    model: gamepulse
    explore: user_facts
    type: single_value
    fields:
    - user_facts.total_revenue
    listen:
      Date: user_facts.player_first_seen_date
      Game: user_facts.game_name
    row: 0
    col: 0
    width: 8
    height: 4
  - name: gaming_monetization_1
    title: Acquisition spend
    model: gamepulse
    explore: user_facts
    type: single_value
    fields:
    - user_facts.acquisition_cost
    listen:
      Date: user_facts.player_first_seen_date
      Game: user_facts.game_name
    row: 0
    col: 8
    width: 8
    height: 4
  - name: gaming_monetization_2
    title: Return on ad spend
    model: gamepulse
    explore: user_facts
    type: single_value
    fields:
    - user_facts.roas
    listen:
      Date: user_facts.player_first_seen_date
      Game: user_facts.game_name
    row: 0
    col: 16
    width: 8
    height: 4
  - name: gaming_monetization_3
    title: D7 retention
    model: gamepulse
    explore: user_facts
    type: single_value
    fields:
    - user_facts.d7_retention_rate
    listen:
      Date: user_facts.player_first_seen_date
      Game: user_facts.game_name
    row: 4
    col: 0
    width: 8
    height: 4
  - name: gaming_monetization_detail
    title: Game comparison
    model: gamepulse
    explore: user_facts
    type: looker_grid
    fields:
    - user_facts.game_name
    - user_facts.total_revenue
    - user_facts.acquisition_cost
    - user_facts.roas
    - user_facts.d7_retention_rate
    listen:
      Date: user_facts.player_first_seen_date
      Game: user_facts.game_name
    row: 8
    col: 0
    width: 24
    height: 8
    limit: 500
