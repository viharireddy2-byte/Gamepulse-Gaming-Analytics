# Business intelligence analysis modules

The original three dashboards, seven view implementations, seed behavior, explore definitions, and connection/cache settings are preserved. New views are included through the existing wildcard include paths; new explores are appended to the model. No production application framework or service is introduced. Python tooling is optional development/validation tooling only.

## New dashboards

| Dashboard | Questions and decisions |
|---|---|
| Retention Cohorts | Where does exact-day return fall by cohort, channel, or platform? |
| Acquisition ROI & Campaign Review | Which mature cohorts miss an adjustable revenue target, and is the sample large enough to investigate? |
| Monetization & Revenue Concentration | How do payer conversion, IAP ARPPU, revenue mix, and concentration differ across segments? |
| Funnel Abandonment & Conversion Time | Which ordered step loses sessions, and how long do successful conversions take? |

### Retention cohorts

`retention_cohorts` groups player/day activity into acquisition-date, game, source, campaign, platform, and age-day cells for D0–D30. It preaggregates activity to distinct player dates before joining, so multiple events on one day do not inflate retention. Numerators and denominators include only fully observed UTC days. The dashboard pivots D1/D7/D14/D30, colors cells using explicit thresholds, and plots channel curves.

Select one age before interpreting a total eligible-player count; summing denominators across ages repeats people. Weekly cohorts can contain partially mature dates: each age's rate is weighted by its own eligible population. Platform is the legacy modal platform, not first-touch platform; changing devices later can change a cohort's platform assignment. This preserves the existing identity contract and should be considered when interpreting longitudinal comparisons.

### Campaign performance

`campaign_performance` retains one row per game/player and reuses existing cumulative Dk revenue. Dk spend, revenue, and player counts all use the same maturity eligibility. ROAS is undefined when mature spend is zero. New default planning targets are D1=10%, D7=30%, D14=60%, D30=100%; they are configurable assumptions, not inferred industry benchmarks or forecasts. They do not alter legacy user_facts targets.

D7 review priority is the positive dollar gap to target, with a default minimum of 100 mature players. Status differentiates no paid mature cohort, insufficient sample, below target, and at/above target. The sample guard is a practical threshold, not a significance test. The campaign dashboard excludes Organic by default. For paid campaign decisions keep Organic filtered out; otherwise organic revenue shares a mixed-population ratio with paid spend. Change targets/minimum sample in Explore; dashboard tiles use these defaults.

### Monetization segments

`monetization_segments` is player-grain and exposes lifetime revenue, IAP/ad split, payer conversion, ARPU, and IAP ARPPU. The date control selects acquisition cohorts, not revenue occurrence dates. Value segments retain existing thresholds: non-payer, payer below $100 lifetime IAP, and high value at/above $100.

Top-decile identity is ranked by lifetime total revenue within each game, with player_key as a deterministic tie-breaker and CEIL(N*0.1) members. Dashboard filters do not rerank players. A filtered revenue share measures contribution from these fixed game-wide leaders among the selected population; it is not the top decile recalculated within that population. Small games can have more than exactly 10% of players selected due to rounding.

### Funnel diagnostics

`funnel_diagnostics` extends the existing nonpersistent funnel view. It inherits its parameters, strict timestamp ordering, and event-window semantics. New measures expose step continuation, dropoffs, abandonment, and median elapsed seconds among converters. Four step controls allow different conversion journeys. Counts describe sessions, not unique players. Timing excludes abandoned sessions and is therefore not an unbiased estimate of time-to-convert for all entrants.

Inherited stage SQL is reused rather than copied. Existing funnel fields, defaults, and dashboard remain untouched. Diagnostic joins retain many-to-one player/session contracts.

## Run checks

```bash
python -m pip install -r requirements-dev.txt
python scripts/model_tools.py
python -m unittest discover -s tests -v
python scripts/build_regression.py /tmp/gamepulse-regression.sql
bq --location=US query --use_legacy_sql=false < /tmp/gamepulse-regression.sql
```

The compiler builds the fixture from current model definitions and inherits the funnel implementation, avoiding an independent copied model in the new tests. The legacy regression file remains available. The compatibility snapshot prevents accidental changes to existing runtime files, model settings, and explores. New local tests exercise the SQL with documented dialect adaptations; the native BigQuery run is the target-engine gate.

## Optional varied demo and publication

Run `sql/07_varied_demo.sql` after schema setup to add 5,000 demo players. It uses independent deterministic hashes for game, device, country, channel, and campaign, plus variable return probability, incomplete funnels, and multiple purchase sizes. It owns only `bi-demo-*` event IDs and `bi-player-*` user IDs; reserve these namespaces. Existing `synthetic-*` events remain. For clear demo findings, use a dedicated demo project so legacy rows do not mix into results.

Deletion, insertion, checks, and publication run in one transaction. A failed statement prevents the publication transaction from committing. For external ingestion, `sql/06_publish_validated.sql` validates timestamps, attribution consistency, amounts, and ambiguous equal-time revisions before publishing a new watermark. Stop concurrent ingestion while running it; it does not create immutable source snapshots or synchronize distinct PDT rebuilds. The legacy seed's publication behavior is unchanged for backward compatibility.

## Target-environment integration

`.github/workflows/bi-validation.yml` runs local parsing, dependency checks, compatibility checks, and SQL regressions on pushes and pull requests. The existing hygiene workflow remains.

`.github/workflows/cloud-validation.yml` is an opt-in manual validation workflow. Configure the GitHub `validation` environment with variables GCP_PROJECT_ID, GCP_WORKLOAD_IDENTITY_PROVIDER, GCP_VALIDATION_SERVICE_ACCOUNT, LOOKER_BASE_URL, and LOOKER_PROJECT_ID, plus secrets LOOKER_CLIENT_ID and LOOKER_CLIENT_SECRET. Use Workload Identity Federation rather than committing Google credentials. The BigQuery account needs query-job permission and optional temporary-query-table permissions for the chosen billing project; the fixture does not write permanent project tables.

The Looker job validates the already-deployed production project and Content Validator scope. Deploy/synchronize the intended commit through your usual process first, and compare the returned project digest in Looker. This job neither deploys the checkout nor renders screenshots. Missing credentials cause failure rather than silently reporting success. Summary artifacts contain counts/digest rather than detailed potentially sensitive content messages.

## Compatibility and remaining environment checks

No historical field is removed or redefined. New modules can be rolled back by removing the appended explores and their four view/dashboard files; base modules continue to work. Removing new objects can break saved content built on those new objects, so run Content Validator before rollback.

New PDTs add full-history compute and storage. Retention cross-expands players to 31 age-days before aggregating. Full rebuilds, independent PDT publication ages, approximate platform identity, and lack of enforced tenant policies remain explicit operational limitations. The optional modules do not claim incremental reconstruction, hardware identity, atomic multi-PDT snapshots, or cloud-measured capacity.
