#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 ops/scripts/init-local.py
docker compose config --quiet
docker compose up -d --wait --wait-timeout 240 postgres kafka postgres-exporter prometheus grafana
docker compose run --rm topic-init
test "$(docker compose exec -T postgres psql -U payflow -d payflow -tAc 'SELECT rolsuper FROM pg_roles WHERE rolname = current_user')" = f
for topic in orders.created payments.completed payments.failed payments.dlq; do
  docker compose exec -T kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --describe --topic "$topic"
done
# Real SQL write, backup, delete, restore and restart persistence.
docker compose exec -T postgres psql -U payflow -d payflow -v ON_ERROR_STOP=1 -c 'CREATE TABLE IF NOT EXISTS ops_probe(id integer PRIMARY KEY, note text); INSERT INTO ops_probe VALUES (1, '\''durable'\'') ON CONFLICT DO NOTHING;'
bash ops/scripts/backup-postgres.sh
backup=$(find .local/backups -name '*.dump' -print -quit)
docker compose exec -T postgres psql -U payflow -d payflow -v ON_ERROR_STOP=1 -c 'DROP TABLE ops_probe;'
cat "$backup" | docker compose exec -T postgres pg_restore -U payflow -d payflow --clean --if-exists --exit-on-error
printf 'platform-smoke\n' | docker compose exec -T kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:9092 --topic orders.created
docker compose restart postgres kafka
for i in $(seq 1 60); do
  if docker compose exec -T postgres pg_isready -U payflow -d payflow && docker compose exec -T kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --list; then break; fi
  sleep 3
done
test "$(docker compose exec -T postgres psql -U payflow -d payflow -tAc 'SELECT note FROM ops_probe WHERE id=1')" = durable
# Producer -> broker disk -> consumer, not merely an open TCP port.
docker compose exec -T kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic orders.created --from-beginning --max-messages 1 --timeout-ms 30000 | grep platform-smoke
curl --fail --retry 20 --retry-all-errors --retry-delay 3 http://localhost:9090/-/ready
curl --fail --retry 20 --retry-all-errors --retry-delay 3 http://localhost:3000/api/health
# Wait for the actual exporter-backed metric, not an empty successful query.
for i in $(seq 1 30); do
  curl -fsS 'http://localhost:9090/api/v1/query?query=pg_up' > .local/pg-up.json
  if python3 -c 'import json; x=json.load(open(".local/pg-up.json")); assert any(s["value"][1] == "1" for s in x["data"]["result"])'; then break; fi
  test "$i" -lt 30; sleep 3
done
# Grafana provisioned dashboard must actually exist.
python3 ops/tests/check-grafana.py
docker compose exec -T postgres psql -U payflow -d payflow -c 'DROP TABLE ops_probe;'
echo 'Compose SQL, backup/restore, Kafka and monitoring checks passed.'
