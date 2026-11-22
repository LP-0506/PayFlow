# Problem Statement

## Background

Any system that takes payments talks to a gateway over a network. Networks fail in the awkward middle: the charge succeeds but the response is lost. Clients, load balancers and message brokers all retry. Services restart mid-operation.

## The problem

1. **Duplicate charges.** A retried request charges the customer twice. This costs money, causes refunds and support tickets, and damages trust.
2. **Lost or stuck orders.** A service writes to its database and then publishes an event. If it crashes between the two, the database and the rest of the system disagree forever.
3. **Silent failures.** A payment that keeps failing is retried forever or dropped, and nobody notices.

## Goal

Build a payment pipeline whose correctness can be demonstrated under retries and crashes.

## Requirements

Functional

- F1. Accept an order with an idempotency key and return the same result for repeated requests with that key.
- F2. Process payment asynchronously through Kafka.
- F3. Retry transient gateway failures with exponential backoff and a retry limit.
- F4. Move messages that exhaust retries to a dead-letter queue with the failure reason.
- F5. Expose order status (`PENDING`, `PAID`, `FAILED`, `NEEDS_REVIEW`).
- F6. Run a reconciliation job that finds orders whose state disagrees with the ledger.

Non-functional

- N1. No duplicate charge for one idempotency key, even under concurrent requests.
- N2. No order lost if any single service is killed at any step.
- N3. Order accept latency p95 under 200 ms at 50 requests per second on a laptop.
- N4. Every request carries a trace or correlation ID visible in logs.
- N5. Each merge passes build, tests and security scans in CI.

## Success criteria (how we prove it)

| Test | Pass condition |
|---|---|
| Send the same order 100 times, 20 in parallel | Exactly 1 charge, 1 order |
| Kill the payment worker mid-charge, restart | Order ends in a single terminal state, 1 charge |
| Gateway returns errors 50% of the time | All orders reach `PAID` or the DLQ, none stuck |
| Gateway down for 5 minutes | Orders wait, retry, and complete after recovery |
| Run reconciliation after the above | Zero mismatches, or each one listed |

## Out of scope

Real payment processors, real money, PCI compliance, refunds and chargebacks (stretch goal), a frontend, multi-currency.

## Honest limits

The gateway is a mock, so "exactly once" here means exactly-once effect through idempotency and deduplication, not a guarantee from Kafka alone. The README and resume line should say "built to production patterns".
