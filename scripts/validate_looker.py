"""Validate an already deployed Looker project using API 4.0; never deploys."""
import json
import os
from pathlib import Path
import sys
from urllib.parse import urlencode, quote, urlparse
from urllib.request import Request, urlopen


def main():
    required=['LOOKER_BASE_URL','LOOKER_CLIENT_ID','LOOKER_CLIENT_SECRET','LOOKER_PROJECT_ID']
    missing=[n for n in required if not os.environ.get(n)]
    if missing:
        raise SystemExit('Missing environment variables: '+', '.join(missing))
    base=os.environ['LOOKER_BASE_URL'].rstrip('/')
    if urlparse(base).scheme!='https':
        raise SystemExit('LOOKER_BASE_URL must use HTTPS')
    base=base if base.endswith('/api/4.0') else base+'/api/4.0'
    def request(path,method='GET',payload=None,token=None,form=False):
        data=None if payload is None else (urlencode(payload).encode() if form else json.dumps(payload).encode())
        headers={'Content-Type':'application/x-www-form-urlencoded' if form else 'application/json'}
        if token:headers['Authorization']='token '+token
        with urlopen(Request(base+path,data=data,headers=headers,method=method),timeout=120) as response:
            raw=response.read()
            return json.loads(raw) if raw else None
    token=request('/login','POST',{'client_id':os.environ['LOOKER_CLIENT_ID'],'client_secret':os.environ['LOOKER_CLIENT_SECRET']},form=True)['access_token']
    try:
        # Validate deployed production state, not an unspecified developer branch.
        request('/session','PATCH',{'workspace_id':'production'},token=token)
        project=quote(os.environ['LOOKER_PROJECT_ID'],safe='')
        model=request('/projects/'+project+'/validate','POST',token=token)
        content=request('/content_validation?'+urlencode({'project_names':os.environ['LOOKER_PROJECT_ID']}),token=token)
        errors=[e for e in model.get('errors',[]) if e.get('severity') in ('fatal','error')]
        summary={'workspace':'production','project_digest':model.get('project_digest'),'lookml_error_count':len(errors),'lookml_warning_count':sum(e.get('severity')=='warning' for e in model.get('errors',[])),'unvalidated_model_count':len(model.get('models_not_validated') or []),'content_error_count':len(content.get('content_with_errors') or []),'scope':'Already-deployed remote project; not a validation of an un-deployed checkout or visual rendering'}
        Path('looker-validation-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
        print(json.dumps(summary))
        if errors or summary['content_error_count'] or summary['unvalidated_model_count']:
            raise SystemExit('Looker validation failed; inspect detailed errors within Looker')
    finally:
        request('/logout','DELETE',token=token)


if __name__=='__main__':main()
