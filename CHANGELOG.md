# Changelog

All notable changes to this repository are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·
Versioning: [SemVer](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-07-07

### Added

- `_template/` — the living STD-002 example every new stack copies.
- Stacks: `homepage` (dashboard), `dockge` (read-only stack
  observability, ADR-015), `monitoring` (Prometheus + Alertmanager +
  Grafana + node-exporter + cAdvisor, ADR-005), `uptime-kuma`
  (black-box checks + status page), `duplicati` (nightly encrypted
  backups to the USB pendrive, ADR-007).
- CI and deploy workflows delegating to homelab-ops reusable workflows.
- `CLAUDE.md`: version-pin inventory with couplings and the ADR-014
  upgrade procedure for the application layer.

### Fixed

- monitoring: fresh installs crash-looped on bind-mount ownership
  (Docker creates missing dirs root:root; grafana runs as uid 472,
  prometheus/alertmanager as 65534) — `prepare.sh` now pre-creates and
  chowns the data dirs via the ops pre-deploy hook.
- duplicati: the healthcheck used wget/curl, which the image does not
  ship (exit 127, permanently unhealthy) — replaced with a bash
  `/dev/tcp` probe of the web UI port.
