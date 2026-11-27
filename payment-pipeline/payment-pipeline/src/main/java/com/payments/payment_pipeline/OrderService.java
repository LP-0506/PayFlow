package com.payments.payment_pipeline;
//package com.payments.paymentpipeline; // unga package line-ah maathaama vainga

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

@Service
public class OrderService {

    public record Result(Order order, boolean created) {}

    private final OrderRepository repo;
    private final OrderTxWriter writer;

    public OrderService(OrderRepository repo, OrderTxWriter writer) {
        this.repo = repo;
        this.writer = writer;
    }

    public Result createOrder(String idempotencyKey, CreateOrderRequest req) {
        var existing = repo.findByIdempotencyKey(idempotencyKey);
        if (existing.isPresent()) {
            return new Result(existing.get(), false);
        }
        try {
            var order = new Order(req.customerId(), req.amount(), req.currency(), idempotencyKey);
            String json = String.format(
                "{\"orderId\":\"%s\",\"customerId\":\"%s\",\"amount\":%s,\"currency\":\"%s\"}",
                order.getId(), order.getCustomerId(), order.getAmount(), order.getCurrency());
            return new Result(writer.saveWithOutbox(order, json), true);
        } catch (DataIntegrityViolationException e) {
            return new Result(repo.findByIdempotencyKey(idempotencyKey).orElseThrow(() -> e), false);
        }
    }

    public java.util.Optional<Order> findById(java.util.UUID id) {
        return repo.findById(id);
    }
}