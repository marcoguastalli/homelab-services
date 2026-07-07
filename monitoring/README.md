# monitoring

White-box metrics + alerting
([ADR-005](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-005-monitoring-stack.md)):
Prometheus, Alertmanager, Grafana, node-exporter, cAdvisor — one stack,
one failure domain. Black-box checks live in `uptime-kuma/` and fail
independently.

| UI | Subdomain | Auth |
|---|---|---|
| Grafana | `grafana.kirito.com` | one_factor |
| Prometheus | `prometheus.kirito.com` | two_factor |
| Alertmanager | `alerts.kirito.com` | two_factor |

## Wiring

- Prometheus scrapes `node-exporter:9100` and `cadvisor:8080` on
  `monitoring_internal`, and `traefik:8082` over `net_monitoring`.
- Alert rules are version-controlled in `prometheus/rules/` — host,
  containers, availability, backup (the 26h backup-freshness rule is
  "the alert that matters most", architecture/006).
- The backup metrics arrive via node-exporter's textfile collector
  from `${DATA_ROOT}/monitoring/textfiles/duplicati.prom`, written by
  `duplicati/scripts/report-status.sh`.
- Grafana dashboards and datasources are provisioned from Git
  (`grafana/provisioning/`, `grafana/dashboards/`). Dashboards edited
  in the UI MUST be exported and committed to be kept.

## Notifications (ntfy)

Alertmanager pushes to [ntfy.sh](https://ntfy.sh) topics via
`webhook_configs.url_file` — the topic name is the credential, so the
URLs live on the Pi only (see `.env.example` header for the two files
to create under `/srv/homelab/secrets/monitoring/`). Routing:
critical → immediate push, warning → 24h digest, info → UI only.
The raw Alertmanager JSON body is what arrives on the phone —
functional, not pretty; a formatting bridge is a possible future
improvement, not a dependency.

## Data-dir ownership (`prepare.sh`)

Docker creates missing bind-mount dirs `root:root`, but grafana runs
as uid 472 and prometheus/alertmanager as 65534 — on a fresh install
they crash-loop on "permission denied". `prepare.sh` (run by ops
`deploy.sh` before every `compose up`) creates and chowns the dirs via
a throwaway alpine container, so no manual Pi preparation is needed.
Deploying by hand outside `deploy.sh`? Run `./prepare.sh` first.

## Backup

`dump.sh` exports Grafana's SQLite consistently; the Prometheus TSDB
is deliberately excluded (15-day ephemeral metrics, architecture/006).
Authelia metrics scraping (the last row of the 006 topology) needs
`telemetry.metrics` enabled and `net_monitoring` membership on the
authelia stack — a future homelab-infrastructure PR, tracked there.
