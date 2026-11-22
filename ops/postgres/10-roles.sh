#!/usr/bin/env bash
# Executed by the official image on a new volume only. Values are never logged.
set -euo pipefail
app_password=$(cat /run/secrets/postgres_password)
monitor_password=$(cat /run/secrets/postgres_monitor_password)
psql --username postgres --dbname postgres --set=ON_ERROR_STOP=1 --set=app_password="$app_password" --set=monitor_password="$monitor_password" <<'SQL'
CREATE ROLE payflow LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD :'app_password';
CREATE ROLE payflow_monitor LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD :'monitor_password';
GRANT pg_monitor TO payflow_monitor;
CREATE DATABASE payflow OWNER payflow;
REVOKE ALL ON DATABASE payflow FROM PUBLIC;
GRANT CONNECT ON DATABASE payflow TO payflow_monitor;
SQL
