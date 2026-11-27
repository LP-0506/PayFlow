package com.payments.payment_pipeline;

//package com.payments.paymentpipeline; // unga package line-ah maathaama vainga

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LedgerRepository extends JpaRepository<LedgerEntry, UUID> {
    boolean existsByOrderId(UUID orderId);
}