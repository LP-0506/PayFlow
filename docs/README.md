# PayFlow Docs

Start with the problem, then the design, then the contracts. The ADRs record why the key decisions were made.

## Read in this order

| # | Doc | What it answers |
|---|---|---|
| 1 | [Problem statement](PROBLEM_STATEMENT.md) | What breaks in payment systems, and what we prove |
| 2 | [Architecture](ARCHITECTURE.md) | Services, patterns, data model, delivery semantics |
| 3 | [UML diagrams](uml/README.md) | The same design as pictures: components, flows, states, data, deployment |
| 4 | [API contract](API.md) | Endpoints, requests, responses, errors |
| 5 | [Event schemas](EVENTS.md) | Topics, envelopes, schema rules |
| 6 | [Failure scenarios](FAILURE_SCENARIOS.md) | The 12 failures we inject and the expected outcomes |
| 7 | [Roadmap](ROADMAP.md) | Four-week plan, ownership, working agreement |
| 8 | [ADRs](adr/) | Why outbox, why DB constraints, why a mock gateway |

## Ops docs

Runbooks and operating procedures live in [ops/](ops/README.md), maintained by the DevOps side of the project.

## House rules

- Docs are plain Markdown; diagrams are Mermaid so they render on GitHub.
- Change the design, change the diagrams and the ADR in the same pull request.
- Keep claims honest: the gateway is a mock, so docs say "built to production patterns", never "production ready".
