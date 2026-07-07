#!/usr/bin/env bash
# Pre-deploy hook (run by ops deploy.sh before compose up). Docker
# creates missing bind mounts root:root; postgres:17.5-alpine runs as
# uid 70 (postgres) and refuses to initdb in a root-owned directory.
# chown runs inside a container so the deploy user needs docker, not
# root. Idempotent.

set -Eeuo pipefail

DATA_ROOT="${DATA_ROOT:-/srv/homelab/data}"

docker run --rm -v "${DATA_ROOT}/bookmarks:/b" alpine:3.21 sh -c '
  set -e
  mkdir -p /b/postgres /b/dumps
  chown 70:70 /b/postgres
'
