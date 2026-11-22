# PayFlow

An event-driven order and payment pipeline that stays correct when clients retry and services crash.

> Status: planning. Uses a mock payment gateway only. Built to production patterns, not a production system.

## The problem

When a payment request times out, the client retries. Without protection, the customer is charged twice. When a service crashes between "charge succeeded" and "order marked paid", the order is lost or stuck. PayFlow is a backend that guarantees:

- One order request produces at most one charge, however many times it is sent.
- A crash at any step loses no order and double-charges no one.
- Every failure is retried safely, or parked in a dead-letter queue a human can inspect.

## Stack

| Layer | Choice |
|---|---|
| Services | Java 21, Spring Boot 3 |
| Messaging | Apache Kafka |
| Storage | PostgreSQL |
| Payment gateway | Mock service with injectable failures |
| Packaging | Docker, Docker Compose, later Kubernetes |
| CI/CD | GitHub Actions |
| Observability | Micrometer, Prometheus, Grafana |

## Docs

- [Problem statement](docs/PROBLEM_STATEMENT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [API contract](docs/API.md)
- [Event schemas](docs/EVENTS.md)
- [Failure scenarios and test plan](docs/FAILURE_SCENARIOS.md)
- [Roadmap and ownership](docs/ROADMAP.md)
- [Contributing](CONTRIBUTING.md)
- [Decisions](docs/adr/)

## Run locally (target state)

```bash
docker compose up -d      # kafka, postgres, services, prometheus, grafana
./scripts/smoke-test.sh   # sends the same order 100 times, expects 1 charge
```

These commands become real as the roadmap progresses. Week 1 delivers the first working version.

## Ownership

- Java backend (services, domain logic, tests): the Java developer.
- Platform (CI/CD, containers, security scans, deploy, monitoring, chaos tests): the DevOps developer.
