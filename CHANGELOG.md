# Changelog

All notable changes to this repository are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·
Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added

- `_template/` — the living STD-002 example every new stack copies.
- Stacks: `homepage` (dashboard), `dockge` (read-only stack
  observability, ADR-015), `monitoring` (Prometheus + Alertmanager +
  Grafana + node-exporter + cAdvisor, ADR-005), `uptime-kuma`
  (black-box checks + status page), `duplicati` (nightly encrypted
  backups to the USB pendrive, ADR-007).
- CI and deploy workflows delegating to homelab-ops reusable workflows.
