#!/usr/bin/env bash
# Consistent PostgreSQL dump (STD-002 rule 11), invoked nightly by
# homelab-ops pre-backup-export.sh. pg_dump through the running
# container gives a consistent snapshot without stopping the service;
# the plain-SQL dump lands in the backed-up data root.

set -Eeuo pipefail

DATA_ROOT="${DATA_ROOT:-/srv/homelab/data}"
DUMP_DIR="${DATA_ROOT}/bookmarks/dumps"

mkdir -p "$DUMP_DIR"

if ! docker inspect -f '{{.State.Running}}' bookmarks-db 2>/dev/null | grep -q true; then
  echo "[bookmarks-dump] bookmarks-db not running — skipping" >&2
  exit 0
fi

docker exec bookmarks-db pg_dump -U bookmarks -d bookmarks \
  >"${DUMP_DIR}/bookmarks.sql.tmp"
mv "${DUMP_DIR}/bookmarks.sql.tmp" "${DUMP_DIR}/bookmarks.sql"
printf '[bookmarks-dump] OK: %s\n' "${DUMP_DIR}/bookmarks.sql"
