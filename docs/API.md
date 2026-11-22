# API Contract (v1, draft)

## POST /orders

Headers: `Idempotency-Key: <uuid>` (required), `Content-Type: application/json`

```json
{ "customerId": "c-123", "amount": 49900, "currency": "INR", "paymentMethodToken": "tok_test_visa" }
```

Amount is in the smallest currency unit.

Responses
- `202 Accepted` first time: `{ "orderId": "...", "status": "PENDING" }`
- `200 OK` repeat with same key and same body: the stored response
- `409 Conflict` same key, different body
- `400 Bad Request` missing key or invalid body

## GET /orders/{orderId}

`200` with `{ "orderId", "status", "amount", "currency", "updatedAt" }`, or `404`.

## GET /admin/dlq (internal)

Lists dead-lettered payments with reason and attempts.

## POST /admin/dlq/{id}/replay (internal)

Re-queues one dead-lettered payment. Logged and idempotent.

## Errors

Shape: `{ "error": "CODE", "message": "..." }`. Every response includes `X-Correlation-Id`.
