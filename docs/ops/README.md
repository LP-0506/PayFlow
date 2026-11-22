# PayFlow operations

The platform can run without the Java services. Application delivery remains an integration contract until those services exist. No live payment provider, production cluster or cloud resource is configured.

- [Local infrastructure and application handoff](LOCAL.md)
- [Release and rollback](DELIVERY.md)
- [Monitoring and incident response](RUNBOOKS.md)
- [Security and owner setup](SECURITY.md)
- [Verification boundaries](VERIFICATION.md)
- [Known upstream image findings and development policy](SECURITY_FINDINGS.md)

## Quick start

Requirements: Docker Engine with Compose v2, Python 3, about 4 GB free memory, and ports 5432, 29092, 9090 and 3000 available on localhost.

```sh
python3 ops/scripts/init-local.py
docker compose up -d --wait postgres kafka postgres-exporter prometheus grafana
docker compose run --rm topic-init
```

Open Grafana at http://localhost:3000 (user `admin`). The generated local password is in `.local/secrets/grafana_password` on your machine. Do not send it in chat, put it in a screenshot or commit it. Prometheus is at http://localhost:9090. Both bind to loopback only.

`docker compose down` stops infrastructure and preserves data. `docker compose down -v` **deletes local database, broker and monitoring volumes**. It is for disposable tests, not routine shutdown.

To reproduce the infrastructure acceptance test on a disposable local checkout:

```sh
bash ops/tests/compose-smoke.sh
```

This writes and drops only the `ops_probe` table, restarts Postgres/Kafka and creates a local backup. Do not run it against shared development data. Use the Platform acceptance workflow for an isolated runner.
