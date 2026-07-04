#!/usr/bin/env bash
# Consistent Uptime Kuma export (STD-002 rule 11), invoked nightly by
# homelab-ops pre-backup-export.sh. Kuma's state (monitors, history,
# the admin login) is embedded SQLite; sqlite3 .backup gives a
# consistent copy while it is running. Dumps every *.db at the data
# root so a DB filename change across Kuma versions cannot silently
# empty the backup.

set -Eeuo pipefail

DATA_ROOT="${DATA_ROOT:-/srv/homelab/data}"
KUMA_DIR="${DATA_ROOT}/uptime-kuma"
DUMP_DIR="${DATA_ROOT}/uptime-kuma/dumps"

mkdir -p "$DUMP_DIR"

found=0
while IFS= read -r db; do
  found=1
  base="$(basename "$db")"
  # alpine + apk sqlite over a dedicated sqlite image: predictable tag,
  # single registry dependency (same tradeoff as authelia/dump.sh).
  docker run --rm \
    -v "${KUMA_DIR}:/work:ro" \
    -v "${DUMP_DIR}:/dumps" \
    alpine:3.21 sh -c \
    "apk add --no-cache -q sqlite \
     && sqlite3 'file:/work/${base}?mode=ro' '.backup /dumps/${base}'"
  printf '[uptime-kuma-dump] OK: %s\n' "${DUMP_DIR}/${base}"
done < <(find "$KUMA_DIR" -maxdepth 1 -name '*.db' -type f)

if [[ $found -eq 0 ]]; then
  echo "[uptime-kuma-dump] no *.db yet — skipping" >&2
fi
