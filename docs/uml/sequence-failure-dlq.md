# Sequence: Gateway Failure, Retries and the DLQ

```mermaid
sequenceDiagram
    autonumber
    participant K as Kafka
    participant PW as payment-worker
    participant DB as PostgreSQL
    participant GW as mock-gateway
    participant OS as order-service
    participant T as triage tool

    K->>PW: deliver orders.created
    PW->>DB: INSERT payments ledger row (attempts = 0)
    loop up to 5 attempts, exponential backoff + jitter<br/>(1s, 2s, 4s, 8s, 16s)
        PW->>GW: charge (idempotency key = orderId)
        GW-->>PW: timeout / 5xx
        PW->>DB: attempts + 1, last_error
    end
    Note over PW: retries exhausted
    PW->>K: publish payments.dlq<br/>(reason, attempts, original payload)
    K->>OS: deliver payments.dlq
    OS->>DB: UPDATE order status = NEEDS_REVIEW
    K->>T: deliver payments.dlq
    T->>T: human inspects reason and payload
    alt replay
        T->>OS: POST /admin/dlq/{id}/replay
        OS->>K: re-queue the payment (logged, idempotent)
    else discard
        T->>OS: mark reviewed (logged manual action)
    end
```

A permanent gateway error takes the same path but publishes `payments.failed` instead, and the order becomes `FAILED` without entering the DLQ. See [FAILURE_SCENARIOS.md](../FAILURE_SCENARIOS.md) scenarios 7-9.
