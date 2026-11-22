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
            pg[("PostgreSQL 16<br/>:5432, volume: pgdata")]
            kf["Kafka (KRaft)<br/>:9092"]
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

Everything runs locally through `docker compose up -d`; no cloud resources and no spend. Kubernetes manifests come in week 4 and mirror this layout one pod per service. Exact images, ports and credentials live in `compose.yml` and `.env.example` once the platform work lands; this diagram tracks [ARCHITECTURE.md](../ARCHITECTURE.md#platform-and-security).
