# Architecture and metric contracts

## Data grains

| Model | Grain / primary key | Refresh |
|---|---|---|
| events | game + event ID, SHA256 JSON struct | Persistent, published batch |
| session_facts | game/player/session sequence hash | Persistent, published batch |
| user_facts | game + player hash | Persistent, published batch |
| lifetime_user_facts | game + player hash | Persistent, published batch |
| funnel_explorer | session ID within selected event window | Query-time, parameter dependent |
| level_balancing | player + level hash | Persistent, published batch; last 60 days |
| top_countries | country | Persistent, published batch; lifetime portfolio revenue |

Event and funnel joins to session/player facts are many-to-one. User IDs are never joined across games. Composite keys use JSON structs to avoid ambiguous string concatenation. Session IDs can change after historical inserts; they are analytical keys, not externally stable identifiers.

## Session and funnel semantics

A session starts at the first event or after at least 1,800 seconds of inactivity per player/game. A Session_Started label alone does not split a session. Equal timestamps are ordered by event ID. Revenue is summed exactly once from deduplicated events. Session duration is last minus first event; it excludes unobserved idle time after the final event.

Funnel stages use the earliest matching timestamp strictly after the previously matched stage. All four stages must occur inside the selected event window and session. Equal-time events do not establish ordering. Repeated event labels are supported only with strictly increasing timestamps. A window can start mid-session; its session_start field represents the first event inside that window.

## Revenue, acquisition, and retention

ARPU = event-window total revenue / distinct active players. ARPPU = event-window IAP revenue / distinct IAP payers. ROAS = lifetime IAP plus ad revenue / acquisition cost counted once per player/game. Zero denominators return NULL. Organic installs have zero cost and undefined standalone ROAS. Attribution metadata must be consistent for every player's events.

Dk retention means activity on the exact kth UTC calendar day after first seen. Only players whose kth day has fully finished are included in numerator and denominator. Filter user_facts first-seen date for acquisition cohorts; filtering events and joining user_facts instead reports lifetime facts for active players, a different question.

Progression time is an explicitly approximate first-to-last span capped at 1,440 minutes per player/level. It is not active playtime. Country ranks cover lifetime portfolio revenue, not the current dashboard date filter. High-value segment uses lifetime IAP >= $100; currency is USD.

## Refresh and consistency

Publish a complete pipeline_state row only after the batch passes checks. Looker observes MAX(published_at) and rebuilds dependent PDTs using its dependency graph. Full rebuilds intentionally preserve late-arrival correction and lifetime correctness. No incremental processing or streaming latency is claimed. max_cache_age limits query-cache reuse; it is not a guarantee of daily PDT regeneration. Schedule an explicit daily publication heartbeat for time-sensitive progression windows and monitor rebuilds.

For strict cross-dashboard snapshot consistency, publish immutable warehouse snapshots and rebuild during a controlled maintenance window; the current batch watermark does not make separate PDT rebuilds a single atomic transaction.
