# Delivery and rollback

## What the workflows do

- CI runs the existing Maven/Gradle detection and Compose syntax validation.
- Application containers discovers real build directories, runs their tests, builds a non-root Java image and scans that exact image. Without application code it reports discovery only, not a successful application build.
- Platform acceptance runs real Postgres, Kafka, Prometheus and Grafana. It checks SQL persistence, backup/restore, topics, a broker round trip and monitoring. A separate disposable kind cluster checks the runtime image, actual server-side manifests, restricted Pod Security, a failed rollout and recovery using `rollout undo`.
- The Kubernetes HTTP fixture is plainly labelled under `ops/tests/`. It proves platform wiring, never payment behavior, Kafka consumption, schema migrations or real service readiness.

There is no automatic deployment to an existing cluster, no credential for one and no registry publication. That is deliberate. Choose the deployment destination and registry with the owner before adding their credentials, package permissions, budget or public exposure. A working disposable-cluster delivery gate is not a production release.

## Kubernetes application base

`ops/kubernetes/base` provides four ClusterIP Services and Deployments. It has no public Ingress, load balancer, database or broker. It requires an existing namespace, external Postgres and Kafka endpoints and an existing `payflow-runtime` Secret. The Secret's keys are `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`; sensitive Kafka auth settings also go there when the selected broker requires them. Use a secret manager to provision them, never a committed YAML Secret.

Create a deployment-specific Kustomize overlay outside the demo. Set its namespace, replace each `payflow/<service>` image with a registry digest, and override `SPRING_KAFKA_BOOTSTRAP_SERVERS`. Review generated YAML. The demo overlay contains only obviously fake fixture connection settings and is never an application release.

For a selected existing environment:

```sh
kubectl kustomize path/to/reviewed-overlay > /tmp/payflow-release.yml
bash ops/scripts/deploy.sh EXPLICIT_CONTEXT EXPLICIT_NAMESPACE /tmp/payflow-release.yml
# Review server validation and the diff, then deliberately apply:
kubectl --context EXPLICIT_CONTEXT -n EXPLICIT_NAMESPACE diff -f /tmp/payflow-release.yml
bash ops/scripts/deploy.sh EXPLICIT_CONTEXT EXPLICIT_NAMESPACE /tmp/payflow-release.yml --apply
```

The script requires Python PyYAML, rejects fixtures/placeholders/mutable latest tags, requires digest images and namespace consistency, and refuses Secrets, Namespaces and cluster RBAC in a service release. It never silently switches the current context. Namespaces, broker/database access, ingress/TLS and environment secret provisioning are owner-reviewed prerequisites.

## Release checklist

1. Review tests and security results at the exact commit to deploy. Required PR checks are owner configuration, not enforced by merely having YAML workflows.
2. Prove the real service health and metric contracts. Check migration compatibility before rollout. Snapshot/backup the database and prove restore on a separate disposable database.
3. Pin image digests and keep the previous deployment revision. Review actual resource use before adopting the starter limits.
4. Deploy one environment at a time, check readiness, business-ledger consistency, consumer lag, error rate and oldest pending order.
5. Record commit, image digests, schema version, deploy time, checks and operator. Do not call a release successful from Kubernetes readiness alone.

## Rollback

```sh
bash ops/scripts/rollback.sh EXPLICIT_CONTEXT EXPLICIT_NAMESPACE order-service PRIOR_REVISION
# Only after checking schema/backward compatibility:
bash ops/scripts/rollback.sh EXPLICIT_CONTEXT EXPLICIT_NAMESPACE order-service PRIOR_REVISION --apply
```

Rollback returns application Pods to an older revision. It does not reverse database migrations, undo charges, replay Kafka messages, restore deleted data or fix incompatible event schemas. Never blindly restore a database after a payment attempt. If correctness is uncertain, stop new order intake, preserve evidence and reconcile with the application owner first.
