#!/usr/bin/env bash
# Source from local-only helpers. Reject obvious remote Docker endpoints.
endpoint=${DOCKER_HOST:-$(docker context inspect "$(docker context show)" --format '{{.Endpoints.docker.Host}}')}
case "$endpoint" in
  unix://*) ;;
  *) echo 'Refusing a remote/non-Unix Docker endpoint for local-only operations'; exit 2;;
esac
unset endpoint
