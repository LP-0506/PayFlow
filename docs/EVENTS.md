# Event Schemas (draft)

All events are JSON with a common envelope: `eventId`, `type`, `occurredAt`, `correlationId`, `data`.

| Topic | Key | Producer | Consumer |
|---|---|---|---|
| `orders.created` | orderId | order-service (outbox relay) | payment-worker |
| `payments.completed` | orderId | payment-worker | order-service |
| `payments.failed` | orderId | payment-worker | order-service |
| `payments.dlq` | orderId | payment-worker | triage tool |

Keying by `orderId` keeps all events for one order in order within a partition.

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

## payments.dlq

```json
{ "type": "PaymentDeadLettered", "data": { "orderId": "uuid", "reason": "GATEWAY_TIMEOUT", "attempts": 5, "originalEvent": { } } }
```

## Rules

- Schema changes are additive only. Add fields, never repurpose them.
- Consumers ignore unknown fields.
- Consumers must tolerate duplicates and out-of-order delivery across keys.
