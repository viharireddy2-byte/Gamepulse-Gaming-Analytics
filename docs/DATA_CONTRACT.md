# Database and query interface

The database DDL in `sql/01_schema.sql` is authoritative. Dataset is `gamepulse` in the connection's selected project; region is US. All timestamps use UTC. Amounts are USD NUMERIC. This repository exposes Looker explores, not a custom HTTP API. Use Looker's existing authenticated interface/API if integration is needed; no new API service is implemented.

| Fields | Contract |
|---|---|
| event_id, game_name | Immutable logical event key; retries reuse it |
| event | Business occurrence timestamp; raw partition key |
| ingested_at | Arrival timestamp used for latest-write deduplication |
| user_id | Pseudonymous player identifier scoped to a game |
| player_first_seen | True first observation, consistent across player history |
| event_name | Gameplay label; twelve standard labels modeled in event lifetime facts |
| install_cost | Total acquisition cost repeated as a player attribute, never summed per event |
| install_source, campaign_name | Immutable attribution attributes per player/game |
| iap_revenue, ad_revenue | Nonnegative revenue for this event; NULL treated as zero |
| player_level | Integer gameplay progression level |
| country, device_platform, game_version | Event-time attributes |

All NOT NULL columns in DDL must be supplied. For optional attribution, use explicit `Unknown` and zero cost only when that meaning is accurate. Refunds and multi-currency accounting require a separate signed transaction contract before adoption. Multiple ingestion revisions with identical timestamps must have identical contents; otherwise latest-write ordering is undefined and upstream must supply a tie-break version.

Example business query: open user_facts, group by game_name and player_first_seen_month, select d7_retention_rate and roas. Open events, filter event_date, group by game_name and event_date, select active_users and total_revenue. Do not sum daily distinct-user counts to estimate monthly active users.

Privacy: store pseudonymous IDs only. Restrict raw event and player-history explores to authorized analysts through Looker model permissions. There is no tenant isolation policy in this project; configure separate roles/models or warehouse row policies before using it for multiple customers.

Optional telemetry columns: continent, region, device_brand, device_language, device_model, device_os_version, ad_network, campaign_id, and campaign_type. Seed rows leave these NULL. Device diversity currently counts platforms, not hardware identifiers. Dk revenue is cumulative through day k; ROAS denominators and revenue use only fully mature cohorts. ROAS targets are analyst-configurable planning assumptions, not forecasts.
