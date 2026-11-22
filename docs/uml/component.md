# Component Diagram

```mermaid
flowchart TB
    client["Client / load script"]

    subgraph payflow["PayFlow"]
        os["order-service<br/>REST API, idempotency check,<br/>outbox writer + relay"]
        pw["payment-worker<br/>dedupe, retries, ledger"]
        rc["reconciler<br/>scheduled job"]
        tt["triage tool<br/>DLQ replay / discard"]
    end

    db[("PostgreSQL<br/>orders, outbox, payments")]
    kafka["Kafka<br/>orders.created<br/>payments.completed / .failed / .dlq"]
    gw["mock-gateway<br/>configurable latency, errors, timeouts"]

    obs["Prometheus + Grafana<br/>metrics, alerts on DLQ depth<br/>and stuck PENDING"]

    client -->|"POST /orders (Idempotency-Key)"| os
    os -->|"1. order row + outbox row,<br/>one transaction"| db
    os -->|"2. relay polls outbox,<br/>publishes orders.created"| kafka
    kafka -->|"3. consume"| pw
    pw <-->|"4. charge, order id as<br/>gateway idempotency key"| gw
    pw -->|"5. ledger row,<br/>unique on order_id"| db
    pw -->|"6. payments.completed / .failed"| kafka
    pw -->|"6b. payments.dlq when<br/>retries exhausted"| kafka
    kafka -->|"7. update order status"| os
    kafka --> tt
    rc -->|"compare orders vs ledger"| db
    os -.-> obs
    pw -.-> obs
```

Ownership: the Java developer owns the four services; the DevOps developer owns PostgreSQL, Kafka and the observability stack as running infrastructure. See [ARCHITECTURE.md](../ARCHITECTURE.md#services).
