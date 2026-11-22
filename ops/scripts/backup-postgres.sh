#!/usr/bin/env bash
# Local development backup only, no business writes and no secrets in logs.
set -euo pipefail
cd "$(dirname "$0")/../.."
umask 077
mkdir -p .local/backups
path=".local/backups/payflow-$(date -u +%Y%m%dT%H%M%SZ).dump"
trap 'rm -f "${path}.partial"' EXIT
docker compose exec -T postgres pg_dump -U payflow -d payflow --format=custom > "${path}.partial"
test -s "${path}.partial"
mv "${path}.partial" "$path"
printf 'Backup saved: %s\n' "$path"
