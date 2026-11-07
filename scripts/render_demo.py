"""Render the executed synthetic analysis; not a Looker dashboard screenshot."""
import argparse
import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter


def render(source, output):
    data=json.loads(source.read_text())
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'axes.spines.top':False,'axes.spines.right':False})
    fig,axes=plt.subplots(2,2,figsize=(13,8.8))
    fig.patch.set_facecolor('#f4f7fb')
    fig.suptitle('GamePulse | Synthetic BI Analysis',fontsize=21,fontweight='bold',x=.06,ha='left',y=.97,color='#142b46')
    w=data['workload']
    fig.text(.06,.915,f"{w['players']:,} players  •  {w['events']:,} events  •  {w['sessions']:,} sessions  |  Local SQL execution",fontsize=11,color='#52647b')
    a=axes[0,0];rows=data['retention'];a.plot([r['age_day'] for r in rows],[r['rate'] for r in rows],'-o',color='#257c88',linewidth=3)
    a.set(title='Exact-day return by eligible population',xlabel='Days since acquisition',ylabel='Retention');a.yaxis.set_major_formatter(PercentFormatter(1));a.set_ylim(0,1);a.set_xticks([1,7,14,30]);a.grid(axis='y',alpha=.15)
    a=axes[0,1];rows=data['campaigns'];a.barh([r['campaign_name'] for r in rows],[r['roas'] for r in rows],color='#5277b5');a.axvline(.3,color='#b9574c',ls='--',label='Default D7 planning target (30%)');a.xaxis.set_major_formatter(PercentFormatter(1));a.set(title='Mature paid-cohort D7 ROAS',xlabel='Cumulative revenue / acquisition spend');a.legend(fontsize=8,loc='lower right')
    a=axes[1,0];rows=data['monetization'];a.bar([r['value_segment'] for r in rows],[float(r['revenue']) for r in rows],color=['#257c88','#daaf55','#8796af']);a.set(title='Lifetime revenue by value segment',ylabel='Synthetic USD revenue');a.text(.98,.93,f"Top-decile share: {data['concentration']['top_decile_share']:.1%}",ha='right',va='top',transform=a.transAxes,color='#142b46');a.grid(axis='y',alpha=.15)
    a=axes[1,1];rows=data['funnel'];a.bar(['Start','Tutorial start','Tutorial complete','Purchase'],[rows['step'+str(i)] for i in range(1,5)],color=['#274765','#376684','#488ba2','#5eafa9']);a.set(title='Strictly ordered session funnel',ylabel='Sessions');a.text(.97,.94,f"Completion: {rows['step4']/rows['step1']:.1%}\nMedian among converters: {rows['median_completion_seconds']:.0f}s",ha='right',va='top',transform=a.transAxes,color='#142b46');a.grid(axis='y',alpha=.15)
    fig.text(.06,.035,'Synthetic data • translated model SQL • fixed analysis date 2026-11-01 • neither customer impact nor cloud performance evidence',fontsize=9,color='#52647b')
    fig.subplots_adjust(left=.085,right=.97,top=.86,bottom=.1,wspace=.32,hspace=.42)
    output.parent.mkdir(parents=True,exist_ok=True);fig.savefig(output,dpi=160,facecolor=fig.get_facecolor());plt.close(fig)


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('source',type=Path);parser.add_argument('output',type=Path)
    args=parser.parse_args();render(args.source,args.output)
