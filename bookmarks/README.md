# bookmarks

Bun/Hono bookmarks API + UI (`ghcr.io/marcoguastalli/app-bookmarks`) with a
dedicated PostgreSQL 17, at `https://bookmarks.kirito.com` behind Authelia.

- App self-migrates at startup (`runMigrations` waits for the DB with
  retries); no init step needed.
- `prepare.sh` pre-creates `${DATA_ROOT}/bookmarks/postgres` owned by uid 70
  (alpine postgres) — Docker would otherwise create it root-owned and initdb
  fails.
- `dump.sh` writes a nightly plain-SQL `pg_dump` to
  `${DATA_ROOT}/bookmarks/dumps/` for the backup cycle.
- Secrets: `/srv/homelab/secrets/bookmarks.env` (see `.env.example`) —
  `POSTGRES_PASSWORD` and the password inside `DATABASE_URL` must match.
- Health: app `GET /health` (probed via 127.0.0.1 — busybox wget resolves
  `localhost` to `::1` but Bun binds IPv4); DB `pg_isready`.

RAM budget (architecture/005): app 128m + db 256m.
