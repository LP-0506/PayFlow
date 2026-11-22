#!/usr/bin/env bash
# Local development backup only, no business writes and no secrets in logs.
set -euo pipefail
cd "$(dirname "$0")/../.."
source ops/scripts/require-local-docker.sh
umask 077
mkdir -p .local/backups
path=".local/backups/payflow-$(date -u +%Y%m%dT%H%M%SZ).dump"
trap 'rm -f "${path}.partial"' EXIT
docker compose exec -T postgres pg_dump -U payflow -d payflow --format=custom > "${path}.partial"
test -s "${path}.partial"
mv "${path}.partial" "$path"
if [ "${1:-}" = --path-only ]; then printf '%s\n' "$path"; else printf 'Backup saved: %s\n' "$path"; fi
