"""Publish findings without secret matches or image filesystem contents."""
import json
from pathlib import Path
output=[]
for path in sorted(Path('.local/raw-image-scans').glob('*.json')):
    document=json.loads(path.read_text())
    entry={'image':document.get('ArtifactName'),'vulnerabilities':[],'secret_findings':[]}
    for result in document.get('Results',[]):
        for v in result.get('Vulnerabilities',[]):
            entry['vulnerabilities'].append({key:v.get(key) for key in ['VulnerabilityID','PkgName','InstalledVersion','FixedVersion','Severity','PrimaryURL']})
        for secret in result.get('Secrets',[]):
            entry['secret_findings'].append({'target':result.get('Target'),'rule':secret.get('RuleID'),'severity':secret.get('Severity')})
    print(entry['image'],len(entry['vulnerabilities']),'fixed HIGH/CRITICAL findings,',len(entry['secret_findings']),'secret findings')
    output.append(entry)
Path('.local/evidence').mkdir(parents=True,exist_ok=True)
Path('.local/evidence/infrastructure-findings.json').write_text(json.dumps(output,indent=2)+'\n')
