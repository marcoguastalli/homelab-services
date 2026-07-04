#!/usr/bin/env bash
# Consistent Grafana export (STD-002 rule 11), invoked nightly by
# homelab-ops pre-backup-export.sh. Grafana's state is a single SQLite
# DB (users, prefs, UI-created dashboards not yet exported to Git);
# sqlite3 .backup gives a consistent copy while grafana is running.
# Prometheus TSDB is deliberately NOT dumped: 15-day metrics are
# ephemeral by design (architecture/006) and excluded from backup.

set -Eeuo pipefail

DATA_ROOT="${DATA_ROOT:-/srv/homelab/data}"
GRAFANA_DIR="${DATA_ROOT}/monitoring/grafana"
DUMP_DIR="${DATA_ROOT}/monitoring/dumps"

mkdir -p "$DUMP_DIR"
[[ -f "${GRAFANA_DIR}/grafana.db" ]] || {
  echo "[monitoring-dump] no grafana.db yet — skipping" >&2
  exit 0
}

# alpine + apk sqlite over a dedicated sqlite image: predictable tag,
# single registry dependency (same tradeoff as authelia/dump.sh).
docker run --rm \
  -v "${GRAFANA_DIR}:/work:ro" \
  -v "${DUMP_DIR}:/dumps" \
  alpine:3.21 sh -c \
  "apk add --no-cache -q sqlite \
   && sqlite3 'file:/work/grafana.db?mode=ro' '.backup /dumps/grafana.db'"
printf '[monitoring-dump] OK: %s\n' "${DUMP_DIR}/grafana.db"
