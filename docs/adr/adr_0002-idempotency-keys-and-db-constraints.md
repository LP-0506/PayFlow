# ADR 0002: Idempotency through unique constraints

Status: accepted

Context: Retries and redelivery cause duplicate requests and messages.

Decision: Enforce uniqueness in Postgres (`orders.idempotency_key`, `payments.order_id`) and treat the constraint as the source of truth, not in-memory checks.

Consequences: Correct under concurrency and restarts. Requires handling constraint violations as "already done", not as errors.
