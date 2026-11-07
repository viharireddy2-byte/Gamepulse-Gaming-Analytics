# Deployment

## Prerequisites

A Google Cloud project with BigQuery billing enabled, the `bq` CLI authenticated to that project, a GitHub repository, and a licensed Looker instance with developer access. BigQuery and Looker must use compatible dataset/PDT locations (this setup uses US). No credentials belong in Git.

## BigQuery setup

From the repository root:

```bash
bq query --use_legacy_sql=false < sql/01_schema.sql
bq query --use_legacy_sql=false < sql/02_seed.sql
bq query --use_legacy_sql=false < sql/03_assertions.sql
bq query --use_legacy_sql=false < sql/05_regression.sql
bq query --use_legacy_sql=false < sql/05_regression.sql
```

The current CLI project is the destination. Set it explicitly with `--project_id` on each command if needed. Schema creation requires dataset creation permission. For Looker, grant the connection service account BigQuery Job User on the billing project, read access on `gamepulse`, and Data Editor on a separate PDT scratch dataset. Enable PDTs in the connection. Grant no raw-dataset write access to dashboard viewers.

Start at the default 100k rows. To generate 50M events, change only `event_count` in the seed script to 50000000. Preview query bytes and set billing limits before running; the script deletes/replaces only the synthetic namespace and therefore must not be run concurrently with another seed job. Synthetic users are prefixed `player-`; reserve this namespace or use a dedicated demo project.

## Looker setup

1. Create a BigQuery Standard SQL connection named `gamepulse_bigquery`, selecting the project containing `gamepulse` and the US scratch dataset.
2. Create a LookML project from the Git repository. No marketplace import or private demo dependency is needed.
3. Configure the model to use the connection, run LookML Validator, and correct environment-specific permission/connection errors.
4. Trigger PDT builds; verify successful dependency builds in the PDT administration panel.
5. Query every explore and compare total event revenue against session and player rollups over the same complete data history.
6. Open all three dashboards and run Content Validator. Confirm filters and funnel parameters.
7. Commit and deploy to Production Mode only after the release checks in OPERATIONS pass.

Validate dashboard rendering and PDT builds in your Looker instance.

## GitHub upload

Unzip the delivery, open a terminal inside its `gamepulse` folder, and run:

```bash
git init -b main
git add .
git commit -m "Build GamePulse gaming analytics platform"
```

Create an empty GitHub repository named `GamePulse-Gaming-Analytics-BI`, copy its remote URL, then run `git remote add origin` followed by that URL and `git push -u origin main`. Keep secrets in the Looker connection settings. Avoid uploading the outer ZIP as the repository content.

## Rollback

Revert the model commit and redeploy through Looker. Validate and rebuild affected PDTs. Warehouse seed changes are separate from model rollback; keep a BigQuery snapshot before replacing any non-demo data.

## Additional BI modules

See [BI module integration](BI_MODULES.md) for the four additional dashboards, opt-in varied demo, validated publication gate, CI checks, and target-environment configuration. Existing setup commands and defaults continue to work.
