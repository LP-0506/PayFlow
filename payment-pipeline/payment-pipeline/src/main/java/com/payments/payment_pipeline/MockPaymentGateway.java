package com.payments.payment_pipeline;
//package com.payments.paymentpipeline; // unga package line-ah maathaama vainga

import java.math.BigDecimal;
import java.util.Random;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class MockPaymentGateway {

    private static final Logger log = LoggerFactory.getLogger(MockPaymentGateway.class);
    private final double failureRate;
    private final Random random = new Random();

    public MockPaymentGateway(@Value("${gateway.failure-rate:0.0}") double failureRate) {
        this.failureRate = failureRate;
    }

    public void charge(String orderId, BigDecimal amount, String currency) {
        if (random.nextDouble() < failureRate) {
            throw new RuntimeException("Gateway error (mock)");
        }
        log.info("CHARGED order={} amount={} {}", orderId, amount, currency);
    }
}
