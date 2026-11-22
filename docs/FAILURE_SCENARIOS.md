# Failure Scenarios and Test Plan

Each scenario becomes an automated test or a chaos script. Write the expected outcome first, then build to it.

| # | Scenario | Injected by | Expected outcome |
|---|---|---|---|
| 1 | Client retries same order 100 times | Load script | 1 order, 1 charge |
| 2 | Same key sent in parallel (20 threads) | Integration test | 1 order, others get stored response |
| 3 | Same key, different body | Integration test | 409, no new order |
| 4 | order-service killed after DB commit, before publish | Kill test | Outbox relay publishes after restart |
| 5 | Relay publishes the same event twice | Test double | Worker charges once |
| 6 | payment-worker killed mid-charge | Chaos script | Redelivery, single charge, single terminal state |
| 7 | Gateway returns 500 half the time | Gateway config | Retries then success, no duplicates |
| 8 | Gateway always times out | Gateway config | Retries exhausted, DLQ, `NEEDS_REVIEW`, alert fires |
| 9 | Gateway succeeds but response lost | Gateway config | Retry uses same gateway idempotency key, no second charge |
| 10 | Kafka broker restarts | Chaos script | No lost orders after recovery |
| 11 | Postgres restarts | Chaos script | Service reconnects, in-flight requests retried by client |
| 12 | Reconciler after all of the above | Scheduled run | Zero unexplained mismatches |

## Evidence to keep

For the README and interviews: a results table with run date, load, and outcome per scenario, plus a Grafana screenshot of the run.
