#!/usr/bin/env bash
# Infrastructure fault injection only, never replay or mutate payment data.
set -euo pipefail
cd "$(dirname "$0")/../.."
case "${1:-}" in kafka|postgres) service=$1;; *) echo 'Usage: chaos-restart.sh kafka|postgres --local-only'; exit 2;; esac
[ "${2:-}" = --local-only ] || { echo 'Only the local Compose project is allowed'; exit 2; }
docker compose restart "$service"
echo 'Restart injected. Business recovery still requires actual application-ledger assertions.'
