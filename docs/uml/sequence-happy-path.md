# Sequence: Happy Path (order to PAID)

```mermaid
sequenceDiagram
    autonumber
    actor C as Client
    participant OS as order-service
    participant DB as PostgreSQL
    participant R as outbox relay
    participant K as Kafka
    participant PW as payment-worker
    participant GW as mock-gateway

    C->>OS: POST /orders (Idempotency-Key, body)
    OS->>DB: INSERT order (PENDING) + outbox row<br/>in one transaction
    OS-->>C: 202 Accepted { orderId, status: PENDING }
    R->>DB: poll unpublished outbox rows
    R->>K: publish orders.created (key = orderId)
    R->>DB: mark outbox row published
    K->>PW: deliver orders.created
    PW->>DB: INSERT payments ledger row<br/>(unique on order_id)
    PW->>GW: charge (idempotency key = orderId)
    GW-->>PW: 200 OK (gateway_ref)
    PW->>DB: mark ledger row succeeded
    PW->>K: publish payments.completed
    K->>OS: deliver payments.completed
    OS->>DB: UPDATE order status = PAID
    C->>OS: GET /orders/{orderId}
    OS-->>C: 200 { status: PAID }
```

The order reaches a single terminal state (`PAID`) with exactly one charge. Every step after the first is asynchronous; the client learns the result through `GET /orders/{orderId}`.
