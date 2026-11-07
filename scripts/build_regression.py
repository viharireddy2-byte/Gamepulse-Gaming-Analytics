"""Build a self-contained BigQuery test from current LookML definitions."""
import argparse
import re
from pathlib import Path
from model_tools import ROOT, load_views, dependency_order, render_sql, measure_sql


def build():
    legacy = (ROOT / 'sql/05_regression.sql').read_text()
    fixture = legacy.split('CREATE TEMP TABLE fixture_events')[0]
    views = load_views()
    for name in dependency_order(views):
        fixture += '\nCREATE TEMP TABLE fixture_' + name + ' AS\n' + render_sql(name, views) + ';\n'
    fixture += '\n' + legacy[legacy.index('ASSERT '):]
    assertions = [
        ("(SELECT SUM(eligible_players) FROM fixture_retention_cohorts WHERE age_day=1)=3", 'Cohort denominators must not fan out'),
        ("(SELECT SUM(retained_players) FROM fixture_retention_cohorts WHERE age_day=1)=0", 'D1 exact-day activity'),
        ("(SELECT SUM(retained_players) FROM fixture_retention_cohorts WHERE age_day=0)=3", 'D0 counts each active player once'),
        ("(SELECT COUNT(*) FROM fixture_campaign_performance)=3", 'Campaign player grain'),
        ("(SELECT COUNT(*) FROM fixture_monetization_segments WHERE revenue_rank=1)=2", 'Rank independently within games'),
    ]

    def metric(view, field, condition, expected, description, source=None, overrides=None):
        expr = measure_sql(view, field, overrides=overrides)
        query = '(SELECT ' + expr + ' FROM ' + (source or 'fixture_' + view) + ' t' + (' WHERE ' + condition if condition else '') + ')'
        assertions.append((query + expected, description))

    metric('monetization_segments', 'payer_conversion', '', ' BETWEEN 0.666666 AND 0.666667', 'Payer conversion uses distinct players')
    metric('monetization_segments', 'arppu', '', ' BETWEEN 4.49499 AND 4.49501', 'ARPPU excludes ad revenue')
    metric('monetization_segments', 'top_decile_revenue_share', '', '=1', 'Top decile concentration fixture')
    metric('campaign_performance', 'd7_review_status', '', "='Insufficient sample'", 'Guard small campaign cohorts')
    metric('campaign_performance', 'd7_review_status', '', "='No paid mature cohort'", 'Organic-only ROAS is undefined', '(SELECT * REPLACE(CAST(0 AS NUMERIC) AS install_cost) FROM fixture_campaign_performance)')
    metric('campaign_performance', 'd7_mature_players', '', '=0', 'Incomplete cohorts excluded', '(SELECT * REPLACE(0 AS cohort_age) FROM fixture_campaign_performance)')
    metric('campaign_performance', 'd7_roas', '', ' IS NULL', 'Zero spend returns NULL', '(SELECT * REPLACE(CAST(0 AS NUMERIC) AS install_cost) FROM fixture_campaign_performance)')
    metric('campaign_performance', 'd7_review_status', '', "='Investigate below target'", 'Below-target campaign review', overrides={'minimum_mature_players':1,'d7_target':10})
    metric('campaign_performance', 'd7_review_status', '', "='At or above target'", 'Above-target campaign review', overrides={'minimum_mature_players':1})
    for field, expected in [('step_1_dropoffs','=1'),('step_2_dropoffs','=1'),('step_3_dropoffs','=0'),('step_1_continuation',' BETWEEN 0.666666 AND 0.666667')]:
        metric('funnel_diagnostics', field, '', expected, 'Funnel diagnostics ' + field)
    fixture += '\nCREATE TEMP TABLE fixture_funnel_custom AS\n' + render_sql('funnel_diagnostics', views, {'step_4': 'Ad_Watched'}) + ';\n'
    assertions.append(("(SELECT COUNT(*) FROM fixture_funnel_custom WHERE step4 IS NOT NULL)=0", 'Parameter changes must not cross sessions'))
    for expression, description in assertions:
        fixture += '\nASSERT (' + expression + ") AS '" + description + "';\n"
    return fixture


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    args.output.write_text(build())
    print('Compiled current model SQL into ' + str(args.output))
