#!/usr/bin/env bash
# Pre-deploy hook (run by ops deploy.sh before compose up). The bind
# mounts must pre-exist with the right owners: Docker creates missing
# ones root:root, and grafana (uid 472) / prometheus / alertmanager
# (uid 65534, nobody) then crash-loop on "permission denied" and fail
# the health gate. chown runs inside a container so the deploy user
# needs docker, not root. Idempotent.

set -Eeuo pipefail

DATA_ROOT="${DATA_ROOT:-/srv/homelab/data}"

docker run --rm -v "${DATA_ROOT}/monitoring:/m" alpine:3.21 sh -c '
  set -e
  mkdir -p /m/prometheus /m/grafana /m/alertmanager /m/textfiles /m/dumps
  chown 65534:65534 /m/prometheus /m/alertmanager
  chown 472:472 /m/grafana
'
