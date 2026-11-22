#!/usr/bin/env python3
"""Generate ignored local-only credentials, never overwrite existing files."""
import os
import secrets
from pathlib import Path
root = Path(__file__).resolve().parents[2]
folder = root / '.local' / 'secrets'
folder.mkdir(parents=True, exist_ok=True, mode=0o700)
folder.chmod(0o700)
for name in ('postgres_password', 'postgres_admin_password', 'postgres_monitor_password', 'grafana_password'):
    path = folder / name
    try:
        fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    except FileExistsError:
        print(f'kept existing {name}')
    else:
        with os.fdopen(fd, 'w') as stream:
            stream.write(secrets.token_urlsafe(32))
        # Compose secrets are file mounts, not an encrypted secret store.
        # Readable to container service UIDs, parent folder remains private.
        path.chmod(0o644)
        print(f'created {name} (value not printed)')
