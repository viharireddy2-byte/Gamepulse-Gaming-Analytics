# Validation status

Completed locally:

- Parsed 11 view definitions and seven dashboard YAML definitions.
- Resolved inherited fields and dashboard field/filter dependencies; checked the PDT dependency graph.
- Parsed model SQL and warehouse scripts using the BigQuery dialect; ASSERT expressions are normalized for syntax inspection only.
- Passed the compatibility snapshot for all original runtime files and model/explore settings.
- Passed 28 SQL assertions in the new current-model regression suite, including legacy correctness cases, cohort denominators, payer conversion, ARPPU, concentration, sample guards, zero-spend ratios, incomplete cohorts, funnel dropoffs, and custom stage parameters.
- Executed the varied local synthetic case study on 5,000 players and 151,149 events. Raw results and reproduction commands are included.

Local execution uses DuckDB only as a development check. Adaptations include UNNEST struct expansion, zero-based offsets, ARRAY_AGG limit handling, and deterministic mode in place of approximate mode. The local varied demo uses SHA256 buckets; BigQuery's optional demo uses FARM_FINGERPRINT. These runs do not certify target-engine behavior or Looker visualization rendering.

Not executed: BigQuery integration jobs, LookML Validator, Content Validator, real dashboard rendering, deployed PDT builds, cloud permission tests, 50M load test, or cloud latency benchmarks. The optional cloud workflow and benchmark runner are implemented and require configured target credentials. No production certification is implied.
