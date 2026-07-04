# _template

The living
[STD-002](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-002-compose-conventions.md)
example. Never deployed (the `_` prefix is excluded from deploy
detection), always CI-validated — so it cannot drift from what CI
accepts.

## Adding a service

Follow the intake checklist in
[architecture/005](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/005-platform-services.md)
and the full procedure in
[RB-002](https://github.com/marcoguastalli/homelab-docs/blob/main/runbooks/RB-002-add-a-new-service.md).
Short version:

1. `cp -r _template <name>` — then replace every `myservice`
   (directory = project = container = router = subdomain, STD-001).
2. Pin the real image tag; set `mem_limit`, healthcheck, port label.
3. Same PR wave: add the catalog row + RAM budget in architecture/005
   and the Authelia `access_control` rule in homelab-infrastructure.
4. On the Pi: create `/srv/homelab/secrets/<name>.env` (mode 0600).
5. Stateful? Add a `dump.sh` writing to `${DATA_ROOT}/<name>/dumps/`
   and keep `kirito.backup: "true"`; otherwise drop the label.
6. Merge (= deploy), verify, add an Uptime Kuma check.
