package com.payments.payment_pipeline;
//package com.payments.paymentpipeline; // unga package line-ah maathaama vainga

import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class OrderTxWriter {

    private final OrderRepository orderRepo;
    private final OutboxRepository outboxRepo;

    public OrderTxWriter(OrderRepository orderRepo, OutboxRepository outboxRepo) {
        this.orderRepo = orderRepo;
        this.outboxRepo = outboxRepo;
    }

    // Rendum save aagum, illa rendum aagaadhu
    @Transactional
    public Order saveWithOutbox(Order order, String json) {
        Order saved = orderRepo.saveAndFlush(order);
        outboxRepo.save(new OutboxEvent("order-created", saved.getId().toString(), json));
        return saved;
    }
}