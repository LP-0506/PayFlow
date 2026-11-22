# Sequence: Duplicate and Concurrent Requests

```mermaid
sequenceDiagram
    autonumber
    actor C as Client
    participant OS as order-service
    participant DB as PostgreSQL

    C->>OS: POST /orders (Idempotency-Key K, body B)
    OS->>DB: INSERT order + outbox row
    OS-->>C: 202 Accepted { orderId, status: PENDING }

    C->>OS: POST /orders (same key K, same body B)<br/>retry after timeout
    OS->>DB: INSERT order (idempotency_key = K)
    DB-->>OS: unique constraint violation
    OS->>DB: SELECT stored order by key K
    OS-->>C: 200 OK, stored response (no new order, no new charge)

    C->>OS: POST /orders (same key K, different body B2)
    OS->>DB: SELECT stored order by key K
    OS-->>C: 409 Conflict (key reused with a different payload)
```

Concurrent duplicates race on the unique constraint: one transaction wins, the losers read the winner's row and return the stored response. The database constraint, not an in-memory check, is the source of truth ([ADR 0002](../adr/adr_0002-idempotency-keys-and-db-constraints.md)).
