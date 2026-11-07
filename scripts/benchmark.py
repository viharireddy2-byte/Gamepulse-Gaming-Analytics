"""Capture real BigQuery job evidence; invoked explicitly with billing limits."""
import argparse
import json
from pathlib import Path
import statistics
import subprocess
import uuid


def execute(args):
    statements=[
        "SELECT game_name,COUNT(*) events,SUM(iap_revenue+ad_revenue) revenue FROM gamepulse.raw_events WHERE FORMAT_TIMESTAMP('%F',event)>=CAST(DATE_SUB(CURRENT_DATE(),INTERVAL 7 DAY) AS STRING) GROUP BY 1",
        "SELECT game_name,COUNT(*) events,SUM(iap_revenue+ad_revenue) revenue FROM gamepulse.raw_events WHERE event>=TIMESTAMP(DATE_SUB(CURRENT_DATE(),INTERVAL 7 DAY)) GROUP BY 1"]
    evidence=[]
    for repetition in range(args.repetitions):
        # Alternate order to reduce systematic first-query effects.
        for variant in ([0,1] if repetition%2==0 else [1,0]):
            job='gamepulse_benchmark_'+uuid.uuid4().hex
            common=['bq','--project_id='+args.project,'--location='+args.location,'--format=json']
            result=subprocess.run(common+['query','--use_legacy_sql=false','--use_cache=false','--maximum_bytes_billed='+str(args.maximum_bytes_billed),'--job_id='+job,statements[variant]],capture_output=True,text=True,check=True)
            output=json.loads(result.stdout)
            metadata=json.loads(subprocess.run(common+['show','--job=true',job],capture_output=True,text=True,check=True).stdout)
            stats=metadata['statistics'];query=stats.get('query',{})
            evidence.append({'variant':['baseline','partition_predicate'][variant],'repetition':repetition,'job_id':job,'elapsed_ms':int(stats['endTime'])-int(stats['startTime']),'bytes_processed':int(query.get('totalBytesProcessed',0)),'slot_ms':int(stats.get('totalSlotMs',query.get('totalSlotMs',0))),'cache_hit':query.get('cacheHit',False),'result':output})
        first,second=evidence[-2:]
        key=lambda row:row['game_name']
        if sorted(first['result'],key=key)!=sorted(second['result'],key=key):
            raise RuntimeError('Benchmark query results differ; do not compare timing')
    summary={}
    for variant in ['baseline','partition_predicate']:
        rows=[r for r in evidence if r['variant']==variant]
        values=sorted(r['elapsed_ms'] for r in rows)
        summary[variant]={'runs':len(rows),'median_ms':statistics.median(values),'p95_ms':values[max(0,__import__('math').ceil(len(values)*.95)-1)],'median_bytes_processed':statistics.median(r['bytes_processed'] for r in rows)}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps({'project':args.project,'location':args.location,'summary':summary,'jobs':evidence},indent=2)+'\n')
    print('Saved actual job evidence to '+str(args.output))


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--project',required=True)
    parser.add_argument('--location',default='US')
    parser.add_argument('--repetitions',type=int,default=10)
    parser.add_argument('--maximum-bytes-billed',type=int,default=10000000000)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    if args.repetitions<2:parser.error('Use at least two repetitions')
    execute(args)
