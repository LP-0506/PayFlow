package com.payments.payment_pipeline;

//package com.payments.paymentpipeline; // unga package line-ah maathaama vainga

import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@EnableScheduling
public class OutboxPublisher {

    private static final Logger log = LoggerFactory.getLogger(OutboxPublisher.class);

    private final OutboxRepository repo;
    private final KafkaTemplate<String, String> kafka;

    public OutboxPublisher(OutboxRepository repo, KafkaTemplate<String, String> kafka) {
        this.repo = repo;
        this.kafka = kafka;
    }

    @Scheduled(fixedDelay = 1000)
    public void publishPending() {
        for (OutboxEvent e : repo.findTop50ByPublishedFalseOrderByCreatedAtAsc()) {
            try {
                // Kafka "received" nu sollura varaikkum wait pannum
                kafka.send(e.getTopic(), e.getEventKey(), e.getPayload()).get(5, TimeUnit.SECONDS);
                e.setPublished(true);
                repo.save(e);
            } catch (Exception ex) {
                log.warn("Kafka not reachable, will retry: {}", ex.getMessage());
                return; // adutha 1 second la thirumba try pannum
            }
        }
    }
}