# Payment Pipeline

Idempotent, crash-safe payment pipeline built to production patterns.

## How it works
POST /orders with an Idempotency-Key header saves the order and an outbox row in one DB transaction.
An outbox publisher sends it to Kafka. A payment worker charges a mock gateway and writes a ledger entry,
then the order becomes PAID. Failures retry with exponential backoff, then go to a dead-letter topic
and the order becomes NEEDS_REVIEW. A reconciliation job compares orders with the ledger.

## Proof
- 100 identical requests, 20 in parallel: exactly 1 order
- Gateway failing: orders reach PAID or the DLQ, none stuck
- Kafka stopped while accepting orders: order still completes after Kafka returns
- Reconciliation: 0 mismatches
- CI: build, tests and CodeQL scan pass on every push

## Honest limits
The gateway is a mock, so "exactly once" here means exactly-once effect through
idempotency and deduplication, not a guarantee from Kafka alone.
Correlation ID appears in HTTP request logs but is not propagated to Kafka consumers.
Latency target (p95 under 200 ms at 50 rps) was not measured.
