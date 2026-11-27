package com.payments.payment_pipeline;

import java.math.BigDecimal;
import java.util.UUID;

public record OrderResponse(
        UUID id, String customerId, BigDecimal amount,
        String currency, OrderStatus status, String idempotencyKey
) {
    public static OrderResponse from(Order o) {
        return new OrderResponse(o.getId(), o.getCustomerId(), o.getAmount(),
                o.getCurrency(), o.getStatus(), o.getIdempotencyKey());
    }
}

