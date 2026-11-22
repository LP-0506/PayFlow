# UML Diagrams

Mermaid diagrams for PayFlow. They render directly on GitHub and each one mirrors a section of [ARCHITECTURE.md](../ARCHITECTURE.md), so update both when the design changes.

| Diagram | Shows |
|---|---|
| [Component](component.md) | Services, stores and topics, and who owns what |
| [Sequence: happy path](sequence-happy-path.md) | One order from POST to `PAID` |
| [Sequence: duplicates](sequence-duplicate-request.md) | Retried and concurrent requests against the idempotency key |
| [Sequence: failure and DLQ](sequence-failure-dlq.md) | Gateway failure, backoff retries, dead-letter and triage |
| [Order state machine](order-state.md) | `PENDING`, `PAID`, `FAILED`, `NEEDS_REVIEW` and legal transitions |
| [Data model (ER)](data-model.md) | `orders`, `outbox`, `payments` and their constraints |
| [Deployment](deployment.md) | Local Docker Compose target layout |

Reading order for someone new: component, happy path, then the two failure-oriented sequences, then state and data model.
