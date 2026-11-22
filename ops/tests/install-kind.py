#!/usr/bin/env python3
import hashlib, json, os, urllib.request
from pathlib import Path
lock=json.loads(Path('ops/tests/tools-lock.json').read_text())
path=Path('.local/bin/kind'); path.parent.mkdir(parents=True, exist_ok=True)
with urllib.request.urlopen(lock['kind_url']) as response:
    data=response.read()
assert hashlib.sha256(data).hexdigest() == lock['kind_sha256'], 'kind checksum mismatch'
path.write_bytes(data); path.chmod(0o755)
print('Verified kind binary installed')
