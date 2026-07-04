# Contributing

Workflow and conventions are defined centrally in
[homelab-docs](https://github.com/marcoguastalli/homelab-docs):
[STD-002 compose](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-002-compose-conventions.md),
[STD-003 traefik](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-003-traefik-conventions.md),
[STD-006 commits & branches](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-006-commit-and-branch-conventions.md).

Repo-specific rules:

1. Merging to `main` **deploys** — the PR template's "which stacks
   redeploy" answer is not decoration.
2. New services start from `_template/` and follow the intake checklist
   in
   [architecture/005](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/005-platform-services.md):
   the same PR wave updates the service catalog (docs) and the Authelia
   `access_control` rules (infrastructure) — default policy is deny, so
   forgetting the rule means 403, not exposure.
3. **No `ports:` in this repo, ever** (STD-002 rule 3) — Traefik,
   Pi-hole and WireGuard in homelab-infrastructure are the only
   published listeners. Everything here joins `net_proxy`.
4. Stateful stacks ship a `dump.sh` (consistent export, STD-002
   rule 11) and label their data `kirito.backup: "true"`.
5. Every compose change must render against its `.env.example`
   (CI enforces; run it locally with
   `docker compose --project-directory <stack> --env-file <stack>/.env.example config -q`).
