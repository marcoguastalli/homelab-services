# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this repo is

The application layer of the kirito.com homelab (Raspberry Pi 5).
Six stacks (`_template`, `homepage`, `dockge`, `monitoring`,
`uptime-kuma`, `duplicati`), deployed by merge-to-main via the
homelab-ops reusable workflows. Conventions live in homelab-docs
(STD-002 compose, STD-003 traefik, architecture/005 service catalog);
this file covers what is repo-specific — above all, **how versions are
upgraded**.

## Where versions are pinned

Image tags are exact pins; `latest`/`stable` are banned (STD-002
rule 2). Every version in this repo, and its coupling:

| Pin | File(s) | Coupling to watch |
|---|---|---|
| Service images | `<stack>/compose.yaml` `image:` lines | — |
| Duplicati image | `duplicati/compose.yaml` **and** `DUPLICATI_IMAGE` in `duplicati/.env.example` | Must match each other, **and** the real `/srv/homelab/secrets/duplicati.env` on the Pi must be edited by hand at deploy time — ops `verify-backup.sh`/`restore-stack.sh` run whatever that file names |
| Dump-helper image | `alpine:3.21` in `monitoring/dump.sh`, `uptime-kuma/dump.sh` | Same pin in `homelab-infrastructure/authelia/dump.sh` — bump all three together |
| Template image | `_template/compose.yaml` (`nginx`) | Never deployed; keep roughly current so copies start sane |
| Reusable workflows | `.github/workflows/{ci,deploy}.yml` reference `homelab-ops@main` | Deliberately unpinned — ops main is the platform contract |

## Upgrade procedure (ADR-014: manual updates, automated reporting)

Updates land in a monthly maintenance window (RB-006), **one PR per
stack**. The weekly `update-report.yml` in homelab-ops maintains a
GitHub issue listing newer tags (skopeo scan of all compose pins), so
discovery is automated — only the decision is manual. Exception:
Trivy HIGH/CRITICAL findings on ingress/auth/VPN components are patched
immediately, not at the window.

Per-stack steps:

1. **Verify the tag exists** — never trust memory; registries move fast
   (see commands below).
2. **Read the release notes** for anything crossing a major/minor:
   - `grafana-oss`: check provisioning-schema and dashboard-JSON
     compatibility; datasource/provider files here are provisioned
     read-only from Git.
   - `prometheus` / `alertmanager`: config flags in `compose.yaml`
     `command:` lists must still exist; `webhook_configs.url_file`
     needs Alertmanager ≥ 0.26.
   - `uptime-kuma`: stay on plain tags (not `-slim`/`-rootless`);
     v1→v2 was a DB migration — majors need a pre-upgrade backup
     (`dump.sh` runs nightly anyway).
   - `duplicati`: only `X.Y.Z.N` stable tags — never `-canary`,
     `-beta`, `-experimental`. Remember the env-file coupling above.
   - `cadvisor`: lives on `gcr.io`, not Docker Hub; confirm arm64
     support in the release assets.
3. **Bump the pin** (and any coupled file from the table).
4. **Validate locally** (CI-identical — see commands below).
5. **PR** using the template: "which stacks redeploy" = the bumped
   stack. Merging **deploys**; the health gate auto-rolls-back a broken
   image, which is the safety net that makes single-PR bumps cheap.
6. **Verify after merge**: Uptime Kuma stays green, the container is
   healthy in Dockge/`docker ps`, and for duplicati the next nightly
   backup metric arrives (`BackupTooOld` fires at 26h if not).

If a bump needs a bigger `mem_limit`, update the RAM budget table in
homelab-docs `architecture/005` in the same PR wave.

## Checking registry tags

`skopeo list-tags docker://<image>` if available; otherwise:

```bash
# Docker Hub (dockge, uptime-kuma, grafana-oss, prom/*, duplicati, alpine, nginx)
curl -s "https://hub.docker.com/v2/repositories/<ns>/<repo>/tags/?page_size=50" \
  | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results']])"

# ghcr (homepage)
TOK=$(curl -s "https://ghcr.io/token?scope=repository:gethomepage/homepage:pull&service=ghcr.io" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")
curl -s -H "Authorization: Bearer $TOK" \
  "https://ghcr.io/v2/gethomepage/homepage/tags/list?n=100"

# gcr (cadvisor)
curl -s "https://gcr.io/v2/cadvisor/cadvisor/tags/list"
```

## Local validation (run before every PR)

```bash
# Compose render, exactly as CI does it
export DATA_ROOT=/srv/homelab/data
for f in */compose.yaml; do d=$(dirname "$f"); \
  docker compose --project-directory "$d" --env-file "$d/.env.example" config -q; done

# Linters (same images/versions as CI behavior)
docker run --rm -v "$PWD:/mnt:ro" koalaman/shellcheck:v0.10.0 -x $(git ls-files '*.sh')
docker run --rm -v "$PWD:/mnt:ro" -w /mnt mvdan/shfmt:v3.10.0 -d -i 2 -bn -ci $(git ls-files '*.sh')
docker run --rm -v "$PWD:/code:ro" -w /code registry.gitlab.com/pipeline-components/yamllint:latest yamllint -s .
docker run --rm -v "$PWD:/workdir:ro" davidanson/markdownlint-cli2:v0.17.2 "**/*.md"
docker run --rm -v "$PWD:/mnt:ro" zricethezav/gitleaks:v8.21.2 detect --source /mnt --no-git --redact

# Monitoring-stack config changes additionally get:
docker run --rm -v "$PWD/monitoring/prometheus:/etc/prometheus:ro" \
  --entrypoint promtool prom/prometheus:<pinned> check config /etc/prometheus/prometheus.yml
docker run --rm -v "$PWD/monitoring/alertmanager:/cfg:ro" \
  --entrypoint amtool prom/alertmanager:<pinned> check-config /cfg/alertmanager.yml
```

## Repo rules Claude must not violate

- **No `ports:` anywhere in this repo** (STD-002 rule 3).
- Secrets never enter Git — `.env.example` holds placeholders only.
- New services start from `_template/` and follow the intake checklist
  in architecture/005 (same PR wave: catalog row + Authelia rule in
  homelab-infrastructure).
- `main` is protected (five `validate / *` contexts, squash-only);
  all changes go through a PR — direct pushes are rejected.
- Push over SSH via the `github.com_mg` remote alias (the HTTPS OAuth
  token lacks `workflow` scope).

The same pin-bump procedure applies to `homelab-infrastructure`
(traefik, authelia, pihole, wireguard) — its couplings are documented
there.
