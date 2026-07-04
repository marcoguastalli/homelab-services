# uptime-kuma

`status.kirito.com` (one_factor) — black-box checks: *is it broken, as
a user sees it*. Complements the Prometheus stack (*why is it broken*);
the two fail independently by design (architecture/006).

## Checks to configure (UI, stored in `/app/data`, backed up)

One HTTP(S) check per row of the
[service catalog](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/005-platform-services.md),
interval 60s, alert after 2 consecutive failures (= the ">2 min down"
rule). Accept the self-signed cert (ADR-011: disable TLS verification
per monitor or trust the wildcard). Point its notification at the same
ntfy critical topic used by Alertmanager — the intake checklist's last
step ("add an Uptime Kuma check") keeps this list current.

## Backup

State is embedded SQLite; `dump.sh` exports it consistently to
`${DATA_ROOT}/uptime-kuma/dumps/` for the nightly Duplicati run.
