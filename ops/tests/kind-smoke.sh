#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${KUBECONFIG:?Use an isolated temporary kubeconfig}"
cluster="payflow-${GITHUB_RUN_ID:-local}"
cleanup() { kind delete cluster --name "$cluster"; }
trap cleanup EXIT
kind create cluster --name "$cluster" --kubeconfig "$KUBECONFIG" --image "$(python3 -c 'import json; print(json.load(open("ops/tests/tools-lock.json"))["node_image"])')" --wait 120s
kind load docker-image payflow-runtime-fixture:ci --name "$cluster"
kubectl apply --server-side --dry-run=server -k ops/kubernetes/demo || true
# Namespace has to exist before server dry-run can validate namespaced resources.
kubectl apply -f ops/kubernetes/demo/namespace.yml
kubectl apply --server-side --dry-run=server -k ops/kubernetes/demo
kubectl apply -k ops/kubernetes/demo
for service in order-service payment-worker mock-gateway reconciler; do
  kubectl -n payflow-demo rollout status "deployment/$service" --timeout=180s
done
kubectl -n payflow-demo get pods -o json > .local/pods.json
python3 - <<'PY'
import json
pods=json.load(open('.local/pods.json'))['items']
assert len(pods)==4
for pod in pods:
 assert pod['spec']['automountServiceAccountToken'] is False
 assert pod['spec']['securityContext']['runAsNonRoot'] is True
 assert all(c['ready'] for c in pod['status']['containerStatuses'])
PY
# Readiness and transport proof via the running Service.
kubectl -n payflow-demo port-forward service/order-service 18080:8080 > .local/port-forward.log 2>&1 &
forward=$!
curl --fail --retry 15 --retry-connrefused --retry-delay 2 http://localhost:18080/actuator/health/readiness
kill "$forward"; wait "$forward" || true
# A bad rollout must be detected, then rollout undo must recover the old image.
kubectl -n payflow-demo set image deployment/order-service app=payflow-runtime-fixture:missing
if kubectl -n payflow-demo rollout status deployment/order-service --timeout=25s; then
  echo 'Bad rollout unexpectedly succeeded'; exit 1
fi
kubectl -n payflow-demo rollout undo deployment/order-service
kubectl -n payflow-demo rollout status deployment/order-service --timeout=180s
test "$(kubectl -n payflow-demo get deployment/order-service -o jsonpath='{.spec.template.spec.containers[0].image}')" = payflow-runtime-fixture:ci
# Denial under restricted Pod Security admission.
if kubectl -n payflow-demo run forbidden --image=busybox:1.37 --privileged --restart=Never --dry-run=server -o yaml > .local/denial.log 2>&1; then
  echo 'Privileged pod unexpectedly admitted'; exit 1
fi
grep -q 'violates PodSecurity' .local/denial.log
echo 'Disposable Kubernetes rollout, rollback and security checks passed (fixture only).'
