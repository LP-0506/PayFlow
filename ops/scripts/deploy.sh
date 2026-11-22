#!/usr/bin/env bash
# Explicit context and reviewed rendered manifest required. No hidden default cluster.
set -euo pipefail
: "${1:?Usage: deploy.sh context namespace rendered-manifest [--apply]}"
: "${2:?Pass the existing target namespace}"
: "${3:?Pass a reviewed rendered manifest}"
context=$1; namespace=$2; manifest=$3
command -v kubectl
if grep -Eq 'integration-required|fixture|:latest' "$manifest"; then
  echo 'Refusing placeholders, fixture images or mutable latest images'; exit 2
fi
# Real app releases must use registry digests and external, pre-provisioned secrets.
python3 - "$manifest" "$namespace" <<'PY'
import sys, yaml
items=list(yaml.safe_load_all(open(sys.argv[1])))
assert items and all(isinstance(x,dict) for x in items)
assert not any(x.get('kind') in ('Secret','Namespace','ClusterRole','ClusterRoleBinding') for x in items), 'Pre-provision secrets/namespaces and keep cluster roles out of app releases'
for obj in items:
 assert obj.get('metadata',{}).get('namespace') == sys.argv[2], 'Every resource must match the explicit namespace'
 if obj.get('kind')=='Deployment':
  assert all('@sha256:' in c['image'] for c in obj['spec']['template']['spec']['containers']), 'Require immutable digest images'
PY
kubectl --context "$context" -n "$namespace" get namespace "$namespace"
kubectl --context "$context" -n "$namespace" apply --dry-run=server -f "$manifest"
if [ "${4:-}" != --apply ]; then
  echo 'Validation only. Review diff, then pass --apply to deploy.'; exit 0
fi
kubectl --context "$context" -n "$namespace" apply -f "$manifest"
for service in order-service payment-worker mock-gateway reconciler; do
  kubectl --context "$context" -n "$namespace" rollout status "deployment/$service" --timeout=180s
done
# Failure does not auto-rollback data/schema. Operator decides after inspection.
