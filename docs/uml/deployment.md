# Deployment Diagram (local target state)

```mermaid
flowchart TB
    subgraph compose["Docker Compose"]
        subgraph apps["Application"]
            os["order-service<br/>Spring Boot 3, Java 21<br/>:8080"]
            pw["payment-worker<br/>Spring Boot 3, Java 21"]
            mg["mock-gateway<br/>:9000"]
        end

        subgraph infra["Infrastructure"]
            pg[("PostgreSQL 17<br/>:5432, volume: postgres-data")]
            kf["Kafka (KRaft)<br/>:29092"]
        end

        subgraph observability["Observability"]
            pr["Prometheus<br/>:9090"]
            gf["Grafana<br/>:3000"]
        end
    end

    client["Client / smoke-test.sh"] -->|"HTTP :8080"| os
    os --> pg
    pw --> pg
    os <-->|"produce / consume"| kf
    pw <-->|"produce / consume"| kf
    pw -->|"HTTP :9000"| mg
    pr -->|"scrape /actuator/prometheus"| os
    pr -->|"scrape /actuator/prometheus"| pw
    gf --> pr
```

Everything runs locally through `docker compose up -d`; no cloud resources and no spend. The infrastructure and observability containers above already run from `compose.yml`; the application containers join it as their images land (see `ops/java/Dockerfile`). Kubernetes manifests under `ops/kubernetes/` mirror this layout one pod per service. Exact images and ports live in `compose.yml`; this diagram tracks [ARCHITECTURE.md](../ARCHITECTURE.md#platform-and-security).
