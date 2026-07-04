#!/usr/bin/env bash
# Duplicati --run-script-after hook (configured on the backup job, see
# README). Writes the node-exporter textfile metrics behind the
# BackupTooOld / BackupFailed alerts — "the alert that matters most"
# (architecture/006). Runs INSIDE the duplicati container; /textfiles
# is ${DATA_ROOT}/monitoring/textfiles on the host.

set -Eeuo pipefail

# Only report on backup runs, not restores/verifies.
[[ ${DUPLICATI__OPERATIONNAME:-} == "Backup" ]] || exit 0

result="${DUPLICATI__PARSED_RESULT:-Unknown}"
ok=0
[[ $result == "Success" || $result == "Warning" ]] && ok=1

# Same-filesystem tmp file so the mv is atomic — node-exporter must
# never scrape a half-written file.
tmp="/textfiles/.duplicati.prom.$$"
{
  printf '# HELP duplicati_last_backup_unixtime Completion time of the last backup run.\n'
  printf '# TYPE duplicati_last_backup_unixtime gauge\n'
  printf 'duplicati_last_backup_unixtime %s\n' "$(date +%s)"
  printf '# HELP duplicati_last_backup_success 1 if the last backup run succeeded.\n'
  printf '# TYPE duplicati_last_backup_success gauge\n'
  printf 'duplicati_last_backup_success %s\n' "$ok"
} >"$tmp"
mv "$tmp" /textfiles/duplicati.prom
