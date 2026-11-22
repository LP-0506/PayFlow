import base64, json, urllib.request
from pathlib import Path
password = Path('.local/secrets/grafana_password').read_text().strip()
auth = base64.b64encode(('admin:'+password).encode()).decode()
request = urllib.request.Request('http://localhost:3000/api/dashboards/uid/payflow-ops', headers={'Authorization':'Basic '+auth})
with urllib.request.urlopen(request) as response:
    dashboard = json.load(response)['dashboard']
assert len(dashboard['panels']) == 8
print('Grafana dashboard provisioned with eight panels')
