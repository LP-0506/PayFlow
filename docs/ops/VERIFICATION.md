# Verification boundaries

## Evidence categories

| Gate | What it proves | What it does not prove |
|---|---|---|
| Compose config | YAML interpolation and structural validity | Containers can start |
| Real Compose infrastructure | SQL write/restart persistence, pg_dump/pg_restore, actual Kafka producer/consumer, provisioned monitoring | Payment correctness or actual Java service integration |
| Real isolated rollout/rollback | Java 21 runtime packaging, API-server manifest validation, readiness, failed rollout detection, undo recovery, restricted admission denial | A production deployment, business readiness, cluster-to-database connectivity or broker authentication |
| Application containers discovery | Whether application build files exist | A build when no build files exist |
| Application build/image job | Actual Maven/Gradle tests and container scan for each discovered build | All 12 payment failure scenarios unless the application test suite implements them |
| Security workflow | Configured scanner results for that commit | Branch protection or a permanently secure system |
| Alert rule tests | Synthetic input causes the intended alerts | Live payment failures or notification delivery |

The runtime fixture responds with `fixture: true` and has no payment code. Demo Kubernetes credentials are deliberately fake. Do not use either as acceptance evidence for the application.

## Repeatable commands

```sh
# Disposable Docker environment only:
bash ops/tests/compose-smoke.sh

# Requires Docker, Java 21, kubectl, Python and the checksum-verified kind helper:
bash ops/tests/build-fixture.sh
docker build -f ops/java/Dockerfile --build-arg JAR_FILE=ops/tests/fixture-out/runtime.jar -t payflow-runtime-fixture:ci .
python3 ops/tests/install-kind.py
export PATH="$PWD/.local/bin:$PATH"
export KUBECONFIG="$(mktemp)"
bash ops/tests/kind-smoke.sh
```

The kind script owns its disposable cluster and removes it on success or failure. It never reads a user's current cluster configuration. Hosted acceptance uses an isolated kubeconfig and no existing context. Use a new temporary path for each local run.

Current run results are linked from GitHub Actions. Only a completed successful run at the relevant commit counts as a pass. Failed and cancelled attempts remain visible; they are not hidden or described as successful. App-specific smoke, concurrency, crash-at-payment-boundary, DLQ replay and reconciliation acceptance remain blocked on her real implementation and its ledger contract.
