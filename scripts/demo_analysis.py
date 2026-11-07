"""Run an offline synthetic BI analysis using current model SQL.

The local bucket function uses SHA256, while BigQuery's optional demo uses
FARM_FINGERPRINT. Distributions follow the same rules; rows are not identical.
"""
import argparse
from datetime import date
import hashlib
import json
from pathlib import Path
import re
import duckdb
import sqlglot
from model_tools import ROOT, load_views, render_sql


def portable(sql):
    sql = re.sub(r' LIMIT 1\)', ')', sql)
    sql = re.sub(r'APPROX_TOP_COUNT\((\w+),1\)\[OFFSET\(0\)\]\.value', r'MODE(\1)', sql)
    return sqlglot.transpile(sql, read='bigquery', write='duckdb')[0]


def run(players=5000):
    db = duckdb.connect()
    db.create_function('bucket', lambda s: int(hashlib.sha256(s.encode()).hexdigest(),16)%100, ['VARCHAR'], 'BIGINT')
    seed = (ROOT/'sql/07_varied_demo.sql').read_text()
    seed = seed[seed.index('WITH players AS ('):seed.index('FROM expanded;')+len('FROM expanded')]
    seed = seed.replace('player_count',str(players)).replace('anchor_date',"DATE '2026-10-31'")
    columns='event_id,event,ingested_at,user_id,game_name,event_name,player_first_seen,country,device_platform,game_version,install_source,campaign_name,install_cost,iap_revenue,ad_revenue,player_level'
    seed_sql=portable(seed)
    # DuckDB ordinality is one-based; BigQuery WITH OFFSET is zero-based.
    seed_sql=re.sub(r'WITH ORDINALITY AS (_t\d+)\(event_label, stage\)',r'WITH ORDINALITY AS \1(event_label, ordinal) CROSS JOIN LATERAL (SELECT ordinal-1 AS stage) AS zero_offset',seed_sql)
    seed_sql=seed_sql.replace("['US', 'GB', 'IN', 'CA'][BUCKET('country-' || CAST(id AS TEXT)) % 4]","['US', 'GB', 'IN', 'CA'][1 + BUCKET('country-' || CAST(id AS TEXT)) % 4]")
    db.execute('CREATE TABLE fixture_raw AS SELECT * FROM ('+seed_sql+') AS t('+columns+')')
    assert db.execute('SELECT COUNT(DISTINCT user_id) FROM fixture_raw').fetchone()[0]==players
    views = load_views()
    for name in ['events','session_facts','user_facts','retention_cohorts','campaign_performance','monetization_segments','funnel_diagnostics']:
        sql = render_sql(name,views)
        sql = sql.replace('CURRENT_DATE()',"DATE '2026-11-01'")
        db.execute('CREATE TABLE fixture_'+name+' AS '+portable(sql))
    def query(sql):
        result=db.execute(sql)
        cols=[d[0] for d in result.description]
        return [dict(zip(cols,row)) for row in result.fetchall()]
    report={
        'environment':'Local DuckDB execution of translated current LookML SQL; synthetic SHA256 bucket input; not BigQuery or Looker performance evidence',
        'synthetic_anchor_date':'2026-10-31', 'as_of_date':'2026-11-01',
        'workload':query('SELECT COUNT(*) events,COUNT(DISTINCT player_key) players,COUNT(DISTINCT unique_session_id) sessions,SUM(iap_revenue+ad_revenue) revenue FROM fixture_events')[0],
        'retention':query('SELECT age_day,SUM(eligible_players) eligible,SUM(retained_players) retained,SUM(retained_players)*1.0/NULLIF(SUM(eligible_players),0) rate FROM fixture_retention_cohorts WHERE age_day IN (1,7,14,30) GROUP BY age_day ORDER BY age_day'),
        'campaigns':query('SELECT campaign_name,COUNT(*) mature_players,SUM(install_cost) spend,SUM(total_d7_revenue) revenue,SUM(total_d7_revenue)/NULLIF(SUM(install_cost),0) roas FROM fixture_campaign_performance WHERE cohort_age>7 AND install_cost>0 GROUP BY campaign_name ORDER BY roas'),
        'monetization':query('SELECT value_segment,COUNT(*) players,COUNT(*) FILTER(WHERE lifetime_iap_revenue>0) payers,SUM(lifetime_revenue) revenue FROM fixture_monetization_segments GROUP BY value_segment ORDER BY revenue DESC'),
        'concentration':query('SELECT SUM(CASE WHEN revenue_rank<=CEIL(game_players*.1) THEN lifetime_revenue ELSE 0 END)/NULLIF(SUM(lifetime_revenue),0) top_decile_share FROM fixture_monetization_segments')[0],
        'funnel':query('SELECT COUNT(step1) step1,COUNT(step2) step2,COUNT(step3) step3,COUNT(step4) step4,MEDIAN(DATE_DIFF(\'second\',step1,step4)) median_completion_seconds FROM fixture_funnel_diagnostics')[0]
    }
    db.close()
    return report


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--players',type=int,default=5000)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    if not 100<=args.players<=500000:parser.error('players must be 100 to 500000')
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(run(args.players),indent=2,default=float)+'\n')
    print('Wrote reproducible synthetic analysis: '+str(args.output))
