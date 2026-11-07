# Performance evidence and measurement

## Current evidence

The repository contains a 50M-event configuration and SQL benchmark queries. No BigQuery scale or latency result has been recorded. The local synthetic BI case study documents executed analytical results; it does not establish BigQuery performance or Looker dashboard latency.

## Capture actual job evidence

After deployment and data validation, run:

```bash
python scripts/benchmark.py --project YOUR_BILLING_PROJECT --location US --repetitions 10 --maximum-bytes-billed 10000000000 --output /tmp/gamepulse-job-evidence.json
```

Replace YOUR_BILLING_PROJECT with the project containing the `gamepulse` dataset. The runner executes two equivalent seven-day revenue queries in alternating order with cache disabled, verifies equal results, and records job IDs, bytes processed, slot-ms, elapsed time, median, and nearest-rank p95. Ten runs provide a coarse p95 estimate; increase repetitions for a stable distribution. Ensure ingestion is quiescent so comparisons use the same rows. Set billing limits appropriate to your data.

The baseline uses a formatted date predicate; the optimized variant uses a direct timestamp range. BigQuery may optimize both similarly. Publish observed results even when there is no improvement. Record region, reservation/edition, slot availability, date distribution, row count, and table bytes alongside the job evidence. Keep sensitive query results out of public artifacts.

Capture PDT build jobs separately. Full-history sessionization and lifetime facts can dominate rebuild cost; partitioning derived output does not eliminate source scans and window shuffles. Compare rollup queries at identical metric grain/time scope and include amortized build cost. Measure Looker dashboard rendering separately from warehouse job execution.

BigQuery manages physical storage, so no user-managed Parquet file-size improvement is claimed. No fictional timing or capacity result is presented as evidence.
