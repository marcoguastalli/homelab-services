# homelab-services

The application layer of the
[kirito.com homelab](https://github.com/marcoguastalli/homelab-docs):
everything the household actually uses, riding on the networks,
certificate and middlewares provided by
[homelab-infrastructure](https://github.com/marcoguastalli/homelab-infrastructure).

Architecture:
[005 services](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/005-platform-services.md),
[006 monitoring](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/006-monitoring-observability.md),
[007 backup](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/007-backup-disaster-recovery.md).
Conventions:
[STD-002 compose](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-002-compose-conventions.md),
[STD-003 traefik](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-003-traefik-conventions.md).

## Stacks

| Stack | Subdomain(s) | Auth | Provides |
|---|---|---|---|
| `_template` | — | — | Living STD-002 example; never deployed (`_` prefix) |
| `homepage` | `home` | one_factor | Dashboard / launcher |
| `dockge` | `dockge` | two_factor | Read-only stack/log view ([ADR-015](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-015-dockge-read-only.md)) |
| `monitoring` | `grafana`, `prometheus`, `alerts` | 1FA / 2FA / 2FA | White-box metrics + alerting ([ADR-005](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-005-monitoring-stack.md)) |
| `uptime-kuma` | `status` | one_factor | Black-box checks + status page |
| `duplicati` | `backup` | two_factor | Nightly AES-256 backup → `/mnt/backup` ([ADR-007](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-007-backup-strategy.md)) |

**Nothing in this repo publishes host ports** (STD-002 rule 3) — all
HTTP surfaces route through Traefik on `net_proxy`; auth policy is
enforced by Authelia's deny-by-default `access_control`
(homelab-infrastructure).

## How changes reach the Pi

PR → CI (`validate / *`, via
[homelab-ops reusable-validate](https://github.com/marcoguastalli/homelab-ops))
→ squash-merge to `main` → `deploy` workflow detects changed stacks →
`deploy.sh` on the Pi's self-hosted runner, one stack at a time, health
gate + auto-rollback. Manual path (first bring-up, GitHub down):
`deploy.sh homelab-services <stack>` directly on the Pi.

## First bring-up

Requires homelab-infrastructure to be up first (networks, TLS,
Authelia, Traefik). Within this repo the order is free; the suggested
sequence surfaces problems earliest:

```bash
DEPLOY=/srv/homelab/repos/homelab-ops/scripts/deploy/deploy.sh
$DEPLOY homelab-services monitoring    # metrics first: watch the rest arrive
$DEPLOY homelab-services homepage
$DEPLOY homelab-services dockge
$DEPLOY homelab-services uptime-kuma
$DEPLOY homelab-services duplicati     # needs /mnt/backup mounted
```

Before the first deploy, create each stack's secrets file on the Pi
from its `.env.example` (`/srv/homelab/secrets/<stack>.env`, mode
0600), plus the two ntfy URL files described in
[monitoring/README](monitoring/README.md).

## Repository layout

```text
_template/    compose.yaml                  copy me (STD-002 living example)
homepage/     compose.yaml  config/         static config, no docker socket
dockge/       compose.yaml                  socket ro, stacks mounted ro
monitoring/   compose.yaml  prometheus/  alertmanager/  grafana/  dump.sh
uptime-kuma/  compose.yaml  dump.sh
duplicati/    compose.yaml  scripts/
```

Every stack ships a complete `.env.example`; CI renders each stack
against it. Secrets never enter this repo
([ADR-008](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-008-secrets-management.md));
gitleaks runs on every PR.
