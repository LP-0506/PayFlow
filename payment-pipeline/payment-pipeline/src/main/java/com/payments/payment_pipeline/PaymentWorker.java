package com.payments.payment_pipeline;
//package com.payments.paymentpipeline; // unga package line-ah maathaama vainga

import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class PaymentWorker {

    private static final Logger log = LoggerFactory.getLogger(PaymentWorker.class);
    private static final Pattern ORDER_ID = Pattern.compile("\"orderId\":\"([^\"]+)\"");

    private final OrderRepository repo;
    private final LedgerRepository ledger;
    private final MockPaymentGateway gateway;

    public PaymentWorker(OrderRepository repo, LedgerRepository ledger, MockPaymentGateway gateway) {
        this.repo = repo;
        this.ledger = ledger;
        this.gateway = gateway;
    }

    @KafkaListener(topics = "order-created", groupId = "payment-worker")
    public void onOrderCreated(String message) {
        Matcher m = ORDER_ID.matcher(message);
        if (!m.find()) {
            log.error("Bad message: {}", message);
            return;
        }
        UUID id = UUID.fromString(m.group(1));
        repo.findById(id).ifPresentOrElse(this::process,
                () -> log.warn("Order {} not found, skipping", id));
    }

    private void process(Order order) {
        if (order.getStatus() != OrderStatus.PENDING) {
            log.info("Order {} already {}, skipping", order.getId(), order.getStatus());
            return;
        }
        // Worker crash aagi message thirumba vandha, rendu thadava charge aagaama irukka
        if (!ledger.existsByOrderId(order.getId())) {
            gateway.charge(order.getId().toString(), order.getAmount(), order.getCurrency());
            ledger.save(new LedgerEntry(order.getId(), order.getAmount(), order.getCurrency()));
        }
        order.setStatus(OrderStatus.PAID);
        repo.save(order);
    }
}