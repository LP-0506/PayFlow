# Architecture

## Overview

```
Client
  |  POST /orders  (Idempotency-Key)
  v
+--------------+     one DB transaction      +-------------------+
| order-service| --------------------------> | Postgres (orders, |
| (REST API)   |   order row + outbox row    |  outbox)          |
+--------------+                             +---------+---------+
                                                       | outbox relay polls
                                                       v
                                              +-----------------+
                                              | Kafka           |
                                              | orders.created  |
                                              +--------+--------+
                                                       v
                                             +------------------+    +--------------+
                                             | payment-worker   |--->| mock-gateway |
                                             | dedupe + retries |<---| (fails on    |
                                             +----+--------+----+    |  demand)     |
                                                  |        |         +--------------+
                                   payments.completed   payments.dlq
                                                  v        v
                                          +-------------+  triage tool
                                          | order-service|  (replay / discard)
                                          | updates state|
                                          +-------------+
                       reconciler (scheduled): compares orders vs payment ledger
```

## Diagrams

The full Mermaid set lives in [uml/](uml/README.md): [component](uml/component.md), [happy-path sequence](uml/sequence-happy-path.md), [duplicate-request sequence](uml/sequence-duplicate-request.md), [failure and DLQ sequence](uml/sequence-failure-dlq.md), [order state machine](uml/order-state.md), [data model](uml/data-model.md) and [deployment](uml/deployment.md). Update them in the same change as any design change.

## Services

| Service | Responsibility | Owner |
|---|---|---|
| order-service | REST API, idempotency check, order state, outbox writer and relay | Java dev |
| payment-worker | Consumes order events, calls gateway, retries, writes ledger, emits results | Java dev |
| mock-gateway | Fake processor with configurable latency, errors, timeouts | Java dev (simple), DevOps (chaos settings) |
| reconciler | Scheduled job comparing orders and ledger | Java dev |
| platform | Compose, CI/CD, scans, Kubernetes, dashboards, alerts, chaos scripts | DevOps dev |

## Key design patterns

### 1. Idempotency keys
The client sends `Idempotency-Key`. The `orders` table has a unique constraint on it. A repeat request returns the stored response. Concurrent duplicates race on the constraint, and the loser reads the winner's row.

### 2. Transactional outbox
The order row and an `outbox` row are written in one database transaction. A relay publishes outbox rows to Kafka and marks them sent. A crash between the two steps cannot lose an event, because the outbox row survives and is published on restart. This can publish twice, so consumers must dedupe.

### 3. Idempotent consumer
The payment worker records `(order_id, attempt_scope)` in a `payments` ledger with a unique constraint before calling the gateway, and passes the order ID to the gateway as its own idempotency key. A redelivered message finds the existing ledger row and skips the charge.

### 4. Retries and dead-letter queue
Transient errors retry with exponential backoff and jitter (for example 1s, 2s, 4s, 8s, 16s, five attempts). After the last attempt the message goes to `payments.dlq` with error, attempt count and original payload, and the order becomes `NEEDS_REVIEW`.

### 5. Reconciliation
A scheduled job lists orders in `PENDING` past a threshold, and ledger rows with no matching order state. It reports them as a metric and a log line, and can fix safe cases.

## Data model (summary)

- `orders(id, idempotency_key UNIQUE, amount, currency, status, created_at, updated_at)`
- `outbox(id, aggregate_id, topic, payload, created_at, published_at)`
- `payments(id, order_id UNIQUE, gateway_ref, status, attempts, last_error, created_at)`

Diagram: [uml/data-model.md](uml/data-model.md).

## Order state machine

`PENDING -> PAID`, `PENDING -> FAILED` (permanent error), `PENDING -> NEEDS_REVIEW` (retries exhausted). Terminal states never change except by an explicit, logged manual action. Diagram: [uml/order-state.md](uml/order-state.md).

## Delivery semantics

Kafka gives at-least-once delivery here. Correctness comes from deduplication in the consumer plus the unique constraints. The system achieves exactly-once effect, not exactly-once delivery.

## Platform and security

- Docker images per service, Compose for local, Kubernetes manifests later.
- CI: build, unit and integration tests (Testcontainers), then SAST, dependency scan, container scan, secret scan. A failing scan blocks merge.
- No secrets in the repo. Config through environment variables.
- Observability: metrics for accepted orders, duplicates blocked, retries, DLQ depth, reconciliation mismatches, and latency. Alerts on DLQ depth and stuck `PENDING`.

## Risks

| Risk | Mitigation |
|---|---|
| Scope creep | Stick to the roadmap, stretch goals last |
| Kafka setup friction | Compose file from week 1 |
| Hard to test crashes | Chaos scripts in week 4, plus Testcontainers kill tests |
