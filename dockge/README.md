# dockge

`dockge.kirito.com` (two_factor) — at-a-glance stack status and
container logs; the convenience layer between `docker ps` and Grafana.

Strictly read-only per
[ADR-015](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-015-dockge-read-only.md):

- `/srv/homelab/repos` (the deployed checkouts) is mounted **ro** —
  Dockge lists the running compose projects via the socket and can show
  their files and logs, but every write fails.
- `DOCKGE_ENABLE_CONSOLE=false` — no shell access through the UI.
- If a Dockge version circumvents the read-only mount, it is removed
  from the platform (the ADR's exit clause).

Because the repo checkouts nest stacks one level deeper than Dockge's
own layout expects (`<repo>/<stack>/compose.yaml`), stacks appear via
socket discovery ("unmanaged") rather than as Dockge-managed entries —
exactly the observation-only posture we want.

State: `${DATA_ROOT}/dockge` holds only its login DB — small, in the
backup set via `kirito.backup`, no consistent-dump hook needed beyond
Duplicati's file copy (single tiny SQLite written rarely; loss is a
one-minute re-setup, accepted).
