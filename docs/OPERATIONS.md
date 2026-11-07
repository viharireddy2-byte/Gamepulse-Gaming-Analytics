# Operations and release gate

## Before production

- Run LookML Validator and Content Validator in the target Looker instance.
- Run warehouse assertions; inspect duplicates before deciding whether to accept latest-ingestion reconciliation.
- Confirm uniqueness of event_key, player_key, session key, and level key in the materialized models.
- Reconcile full-history event revenue = sum of session revenue = sum of player lifetime revenue within USD 0.000001. Revenue comparisons must use identical history and deduplication rules.
- Confirm event counts equal summed session events_in_session and funnel stage counts are nonincreasing.
- Exercise cross-game repeated user IDs, exact 30-minute gaps, tied timestamps, duplicated event revisions, zero revenue/cost, empty data, late historical events, and incomplete retention cohorts.
- Verify model permissions, absence of personal data, billing limits, job location, and scratch permissions.
- Record actual dashboard load times, PDT build duration, refresh freshness, and job IDs. No performance release target is pre-certified.

## Publication and freshness

Run validation after ingestion, publish only complete batches, and monitor the datagroup and each dependent PDT. Investigate failed builds before announcing fresh data. Alert on missing publication, failed assertions, rebuild errors, cost spikes, and revenue reconciliation failures using your existing platform's monitoring. Alert provisioning is environment-specific and is not implemented here.

Late records cause full reconstruction on the next published watermark, including revised sessions and lifetime facts. Build windows can temporarily expose different publication ages across PDTs. Revalidate after historical backfills. Publish a daily heartbeat even without new events to refresh rolling progression data.

## Query safety

Use bounded event dates; unrestricted history is deliberately available for lifetime facts. Apply project-level query limits/reservations and least privilege. Do not enable require_partition_filter on raw_events without redesigning full-history PDT queries: lifetime/session reconstruction currently requires history.
