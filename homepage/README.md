# homepage

`home.kirito.com` (one_factor) — the household launcher.

Deliberately boring: fully static config in `config/`, mounted
read-only file-by-file. No docker socket (architecture/004 limits
socket mounts to traefik/cAdvisor/dockge), so tiles are **declared**,
not discovered — a new service means a new entry in
`config/services.yaml`, which the intake checklist already forces
through a PR.

Stateless: no `${DATA_ROOT}` mount, no `dump.sh`, nothing in the
backup set. Logs go to the ephemeral container fs and `docker logs`.
