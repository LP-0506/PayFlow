#!/usr/bin/env bash
set -euo pipefail
: "${1:?Usage: rollback.sh context namespace service revision --apply}"
: "${2:?Explicit namespace required}"
: "${3:?Service required}"
: "${4:?Known prior revision required}"
case "$3" in order-service|payment-worker|mock-gateway|reconciler) ;; *) echo 'Unknown service'; exit 2;; esac
[[ "$4" =~ ^[1-9][0-9]*$ ]] || { echo 'Revision must be a positive integer'; exit 2; }
kubectl --context "$1" -n "$2" rollout history "deployment/$3"
if [ "${5:-}" != --apply ]; then echo 'Review the revision and migration compatibility, then pass --apply'; exit 0; fi
kubectl --context "$1" -n "$2" rollout undo "deployment/$3" --to-revision="$4"
kubectl --context "$1" -n "$2" rollout status "deployment/$3" --timeout=180s
