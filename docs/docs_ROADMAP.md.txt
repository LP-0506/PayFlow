# Roadmap and Ownership

Four weeks. Two people. Each week ends with something that runs.

| Week | Java dev | DevOps dev | Done when |
|---|---|---|---|
| 1 | order-service: REST, Postgres, idempotency key, tests | Repo, branch rules, Compose (Postgres, Kafka), CI build and test | Duplicate POSTs create one order |
| 2 | Outbox relay, Kafka producer, payment-worker, mock gateway, ledger | Dockerfiles, image build in CI, Testcontainers in CI | Order reaches `PAID` end to end |
| 3 | Retries with backoff, DLQ, status updates, reconciler | Metrics, Prometheus, Grafana, dependency and container scans, secret scan | Failures end in `PAID` or DLQ, dashboards live |
| 4 | Admin replay endpoint, fix bugs found by chaos tests, docs | Chaos scripts, alerts, Kubernetes manifests, deploy, results table | All 12 failure scenarios pass |

## Stretch goals

Refunds, a small status UI, multi-tenant API keys, load test report with k6.

## Working agreement

- Small pull requests, one reviewer from the other person.
- Main is protected. CI must pass.
- Tickets follow the weekly table. One issue per bullet.
- Each person can explain the other's half in an interview. Swap a review each week.

## Interview talking points

- Why idempotency keys, and what happens on concurrent duplicates.
- Why the outbox pattern, and what breaks without it.
- At-least-once delivery plus dedupe versus "exactly-once".
- How retries, backoff and jitter prevent overload.
- What you measure and how you proved it works under failure.
