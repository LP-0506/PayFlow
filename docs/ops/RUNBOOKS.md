# Monitoring and incident response

## Dashboard and metric contract

Grafana provisions the PayFlow operations dashboard and a Prometheus datasource. Postgres availability and scrape health are infrastructure metrics. Application panels honestly show **No data** until her services implement the proposed Micrometer meters below. Do not replace missing data with zero or treat absent business alerts as proof of health.

| Prometheus metric | Meaning required from the Java services |
|---|---|
| `payflow_orders_accepted_total` | New accepted orders, not duplicate responses |
| `payflow_duplicates_blocked_total` | Duplicate requests safely served from stored state |
| `payflow_payment_retries_total` | Retry attempts, not original charges |
| `payflow_dlq_depth` | Outstanding review items, decremented only after safe disposition |
| `payflow_pending_oldest_age_seconds` | Age of the oldest still-pending order, zero only when actually none |
| `payflow_reconciliation_mismatches` | Current unresolved order/ledger inconsistencies |

Avoid order IDs, customer IDs, idempotency keys and gateway references in metric labels. They create unbounded cardinality and can disclose sensitive data. Put sanitized correlation IDs in structured logs instead. Never log payment tokens or the full event payload by default.

The starter alerts cover exporter/target availability, DLQ items, old pending orders and reconciliation mismatches. Five minutes for a stuck order is a proposed demo objective, not a measured business SLA. Tune after actual load and payment behavior exist. Prometheus displays alerts locally; **no paging or notification destination is configured**. Choose that destination before adding Alertmanager integrations.

## Postgres unavailable

1. Confirm `docker compose ps` and `docker compose logs --tail=100 postgres postgres-exporter`. Check disk, memory and the database health check.
2. Stop destructive troubleshooting. Preserve the named volume. Do not run `down -v`.
3. If only the exporter is down, investigate its connection configuration. Do not claim a database outage from the exporter alone.
4. After recovery, inspect pending orders, outbox backlog and reconciliation. A healthy database is not proof all payments are correct.

## Kafka unavailable or consumers stuck

1. Check `docker compose logs --tail=100 kafka`, disk capacity and the four expected topic names.
2. From Compose, use `kafka:9092`. From a host process use `localhost:29092`. Mixing advertised listeners often causes connection failures.
3. Inspect actual consumer groups with `kafka-consumer-groups.sh --bootstrap-server kafka:9092 --all-groups --describe` inside the Kafka container. No group exists until her consumers run.
4. Do not reset offsets or delete topics as a recovery shortcut. Preserve data and compare application state before any replay.

No automated Kafka lag alert is claimed in the baseline. It needs a selected exporter or application-owned lag meter and real consumer group names. Console inspection is the current operational path.

## DLQ or reconciliation alert

1. Pause new intake if correctness may be at risk. Record the time, deployment digest, sanitized correlation/order identifier and failure category.
2. Inspect the application's durable ledger and the mock gateway's own charge ledger. A response code or Kafka delivery count is not charge evidence.
3. Classify permanent validation failures separately from transient transport failures. Confirm the same idempotency key is reused for gateway retries.
4. Replay only through her authenticated, audited replay endpoint after its semantics exist and a human approves the case. There is deliberately no blind replay script here.
5. Confirm exactly one charge, one allowed terminal state and no unexplained reconciliation mismatch after recovery.

## Backup and recovery

```sh
bash ops/scripts/backup-postgres.sh
```

Backups are custom-format pg_dump files under ignored `.local/backups`, created with a private umask. Keep backups encrypted and access-controlled when moving them off the laptop. This local copy is not offsite disaster recovery, WAL archiving or point-in-time recovery.

The disposable infrastructure CI writes a probe table, backs it up, drops it and restores it with `pg_restore --exit-on-error`. Production or shared-data restore is not automated: restore into a **new database**, check schema/version/row counts, compare application and gateway ledgers, then agree on cutover. Restoring an old database can otherwise forget completed charges and cause double charging on retry.

## Safe local fault injection

```sh
bash ops/scripts/chaos-restart.sh kafka --local-only
bash ops/scripts/chaos-restart.sh postgres --local-only
```

These scripts only restart the local Compose containers. They do not prove the application's 12 failure scenarios. Add real ledger assertions with the Java developer before recording those scenarios as passed. Never copy this local-only command into an existing production context.
