package com.payments.payment_pipeline;


import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ReconciliationController {

    private static final Logger log = LoggerFactory.getLogger(ReconciliationController.class);

    private final OrderRepository orders;
    private final LedgerRepository ledger;

    public ReconciliationController(OrderRepository orders, LedgerRepository ledger) {
        this.orders = orders;
        this.ledger = ledger;
    }

    @GetMapping("/reconciliation")
    public Map<String, Object> run() {
        List<String> mismatches = reconcile();
        return Map.of("mismatchCount", mismatches.size(), "mismatches", mismatches);
    }

    @Scheduled(fixedDelay = 30000, initialDelay = 30000)
    public void scheduled() {
        List<String> mismatches = reconcile();
        if (mismatches.isEmpty()) {
            log.info("Reconciliation: 0 mismatches");
        } else {
            mismatches.forEach(m -> log.warn("Reconciliation MISMATCH: {}", m));
        }
    }

    public List<String> reconcile() {
        List<String> out = new ArrayList<>();
        Set<UUID> ledgerOrderIds = new HashSet<>();
        ledger.findAll().forEach(l -> ledgerOrderIds.add(l.getOrderId()));
        Instant stuckBefore = Instant.now().minus(2, ChronoUnit.MINUTES);

        for (Order o : orders.findAll()) {
            boolean inLedger = ledgerOrderIds.contains(o.getId());
            if (o.getStatus() == OrderStatus.PAID && !inLedger) {
                out.add("Order " + o.getId() + " is PAID but has no ledger entry");
            }
            if (inLedger && o.getStatus() != OrderStatus.PAID) {
                out.add("Order " + o.getId() + " is " + o.getStatus() + " but ledger shows a charge");
            }
            if (o.getStatus() == OrderStatus.PENDING && o.getCreatedAt().isBefore(stuckBefore)) {
                out.add("Order " + o.getId() + " stuck in PENDING for over 2 minutes");
            }
        }
        return out;
    }
}