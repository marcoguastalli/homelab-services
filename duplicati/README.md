# duplicati

`backup.kirito.com` (two_factor) — nightly encrypted backups per
[ADR-007](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-007-backup-strategy.md)
/
[architecture/007](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/007-backup-disaster-recovery.md).

## The backup job (configured once in the UI, stored in `/data`)

Duplicati job definitions are state, not files — configure the single
job like this and export its JSON to the password manager as belt and
braces:

| Setting | Value |
|---|---|
| Source | `/source` (data + secrets + state, all mounted ro) |
| Exclude | `/source/data/duplicati` (its own live DB — rebuildable via repair) and `/source/data/monitoring/prometheus` (ephemeral TSDB) |
| Target | `file:///backup/homelab` (= `/mnt/backup/homelab` on the host) |
| Encryption | AES-256, passphrase = `DUPLICATI_PASSPHRASE` from the env file |
| Schedule | daily 03:00 (after the 02:30 `pre-backup-export.sh` dumps) |
| Retention | `7D:1D,4W:1W,6M:1M` |
| Advanced | `run-script-after = /scripts/report-status.sh` |

The run-script writes `duplicati.prom` into the shared textfiles dir —
that feeds the `BackupTooOld`/`BackupFailed` alerts (the ones that
matter most). Weekly restorability proof is homelab-ops
`verify-backup.sh`, which sources the same `duplicati.env`.

## Notes

- The healthcheck is a bash `/dev/tcp` connect to the web UI port —
  the image ships neither wget nor curl. It proves the listener is up,
  not that HTTP answers; good enough for the deploy gate.
- `mem_limit: 256m` assumes household-sized backup sets on .NET 8; an
  OOM-killed backup run trips `ContainerOomKilled` + `BackupTooOld` —
  raise the limit via PR and update the architecture/005 budget.
- Restore procedures: RB-003 (single service), RB-004 (bare metal).
