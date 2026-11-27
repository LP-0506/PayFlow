package com.payments.payment_pipeline;

//package com.payments.paymentpipeline; // unga package line-ah maathaama vainga

import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.kafka.support.ExponentialBackOffWithMaxRetries;

@Configuration
public class KafkaErrorConfig {

    private static final Logger log = LoggerFactory.getLogger(KafkaErrorConfig.class);
    private static final Pattern ORDER_ID = Pattern.compile("\"orderId\":\"([^\"]+)\"");

    @Bean
    public DefaultErrorHandler errorHandler(KafkaTemplate<String, String> template, OrderRepository repo) {
        var dlq = new DeadLetterPublishingRecoverer(template);

        DefaultErrorHandler handler = new DefaultErrorHandler((record, ex) -> {
            // Retries mudinjadhum: order-ah NEEDS_REVIEW ah maathi, message-ah DLQ ku anuppum
            Matcher m = ORDER_ID.matcher(String.valueOf(record.value()));
            if (m.find()) {
                repo.findById(UUID.fromString(m.group(1))).ifPresent(o -> {
                    o.setStatus(OrderStatus.NEEDS_REVIEW);
                    repo.save(o);
                });
            }
            log.error("Retries exhausted, sending to DLQ: {}", ex.getMessage());
            dlq.accept(record, ex);
        }, backoff());

        return handler;
    }

    private ExponentialBackOffWithMaxRetries backoff() {
        var b = new ExponentialBackOffWithMaxRetries(5); // 5 retries
        b.setInitialInterval(1000);  // 1 second
        b.setMultiplier(2.0);        // 1s, 2s, 4s, 8s, 10s
        b.setMaxInterval(10000);     // max 10 seconds
        return b;
    }
}