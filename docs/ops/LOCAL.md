# Local infrastructure and Java handoff

## Endpoints

| Consumer | PostgreSQL | Kafka |
|---|---|---|
| Java process on the host | `localhost:5432/payflow` | `localhost:29092` |
| Compose service | `postgres:5432/payflow` | `kafka:9092` |

Database/user: `payflow`. The generated password is mounted as a Compose secret. The Kafka KRaft broker has four explicit topics, each with three partitions: `orders.created`, `payments.completed`, `payments.failed`, `payments.dlq`. Auto-creation is off. One broker and replication factor one are intentional **local-only** settings, not high availability.

Local data lives in named volumes. Neither `.local/` nor `.env` is committed. Compose secret files are not encrypted at rest. The initialization script will not overwrite existing passwords. Changing a password file does not rotate an existing PostgreSQL role or an existing Grafana admin account. Change those through the product's supported mechanism, or recreate only a disposable volume.

## Runtime contract to agree with the Java developer

Each long-running service produces one executable Java 21 jar, listens on port 8080, runs as UID/GID 10001 and writes only to `/tmp`. Configure graceful shutdown. Worker and reconciler also need an HTTP management listener for health checks. If the reconciler becomes a scheduled one-shot job instead, replace its Deployment with a CronJob rather than faking readiness.

Spring Boot Actuator with Micrometer Prometheus must expose:

- `/actuator/health/liveness` for process health. Do not include external systems in liveness.
- `/actuator/health/readiness` for ability to serve the service's work. Define dependency checks in application configuration.
- `/actuator/prometheus` on the internal management interface. Do not expose credentials, config or environment endpoints.

Configuration accepted by the platform: `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `SPRING_KAFKA_BOOTSTRAP_SERVERS`. Compose supplies the password through Spring's config-tree import instead of a plaintext YAML value. `PAYFLOW_GATEWAY_BASE_URL` is a **proposed application-specific property**; her code must bind it explicitly or the platform must adapt to the actual property. It is not claimed to be implemented.

Use a mock payment gateway only. No real customer data or payment credentials belong in this demonstration. Database migrations and application-ledger assertions are owned with the Java developer; the platform does not create business tables.

## Package real services

```sh
bash ops/scripts/package-service.sh ./order-service payflow/order-service:local
```

Repeat using each actual service directory and an explicit image name. Maven `verify` or Gradle `build` must pass first. The script refuses missing builds and ambiguous jars. It will not substitute the runtime test fixture for her application. Maven/Gradle wrappers and their integrity settings should be committed by the application owner.

The separate application overlay intentionally fails until all four real image names are supplied:

```sh
export ORDER_SERVICE_IMAGE=payflow/order-service:local
export PAYMENT_WORKER_IMAGE=payflow/payment-worker:local
export MOCK_GATEWAY_IMAGE=payflow/mock-gateway:local
export RECONCILER_IMAGE=payflow/reconciler:local
docker compose -f compose.yml -f ops/compose/apps.yml config --quiet
docker compose -f compose.yml -f ops/compose/apps.yml up -d
```

This is a future handoff command, not evidence of current PayFlow service readiness. The base infrastructure starts independently today. There is deliberately no script claiming one charge from 100 requests until a trustworthy gateway ledger endpoint or SQL contract exists. Repeated HTTP 200s alone cannot prove no double charge.
