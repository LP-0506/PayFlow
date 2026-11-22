# Event Schemas (draft)

All events are JSON with a common envelope: `eventId`, `type`, `occurredAt`, `correlationId`, `data`.

| Topic | Key | Producer | Consumer |
|---|---|---|---|
| `orders.created` | orderId | order-service (outbox relay) | payment-worker |
| `payments.completed` | orderId | payment-worker | order-service |
| `payments.failed` | orderId | payment-worker | order-service |
| `payments.dlq` | orderId | payment-worker | order-service (sets `NEEDS_REVIEW`), triage tool |

Keying by `orderId` keeps all events for one order in order within a partition.

The two abbreviated examples below omit the common envelope fields for readability.

## orders.created

```json
{ "eventId": "uuid", "type": "OrderCreated", "occurredAt": "2026-01-01T10:00:00Z",
  "correlationId": "uuid",
  "data": { "orderId": "uuid", "amount": 49900, "currency": "INR", "paymentMethodToken": "tok_test_visa" } }
```

## payments.completed

```json
{ "type": "PaymentCompleted", "data": { "orderId": "uuid", "gatewayRef": "gw_123", "attempts": 2 } }
```

## payments.failed

Published when the gateway rejects the charge permanently (for example a declined card), so retrying cannot help.

```json
{ "type": "PaymentFailed", "data": { "orderId": "uuid", "reason": "CARD_DECLINED", "attempts": 1 } }
```

The order becomes `FAILED`, and nothing goes to the DLQ.

## payments.dlq

```json
{ "type": "PaymentDeadLettered", "data": { "orderId": "uuid", "reason": "GATEWAY_TIMEOUT", "attempts": 5, "originalEvent": { } } }
```

order-service consumes this to set the order to `NEEDS_REVIEW`; the triage tool consumes it for human inspection and replay. The retry and dead-letter flow is diagrammed in [uml/sequence-failure-dlq.md](uml/sequence-failure-dlq.md).

## Rules

- Schema changes are additive only. Add fields, never repurpose them.
- Consumers ignore unknown fields.
- Consumers must tolerate duplicates and out-of-order delivery across keys.
