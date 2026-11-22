# ADR 0003: Mock payment gateway

Status: accepted

Context: Real processors add cost, compliance scope and flaky test setup.

Decision: Build a mock gateway that can add latency, errors, timeouts and lost responses on demand, and that honours an idempotency key like real gateways do.

Consequences: Failure tests are repeatable. The project must not claim production readiness.
