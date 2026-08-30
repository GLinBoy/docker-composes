# Wiki.js

[Wiki.js](https://js.wiki/) is a modern, open-source wiki built on Node.js. This stack runs the
official [ghcr.io/requarks/wiki](https://github.com/requarks/wiki) image (Alpine-based) against a
PostgreSQL database using the official [postgres image](https://hub.docker.com/_/postgres)
(Alpine variant).

The compose healthchecks probe PostgreSQL with `pg_isready` and the web UI with `curl` (the Wiki.js
image ships `bash` + `curl`).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Then set in `.env`:

- `WIKIJS_DB_PASSWORD` — database password, e.g. `openssl rand -hex 32`.

The image is pinned to `ghcr.io/requarks/wiki:2.5` — a floating *minor* tag that keeps pulling the
latest 2.5.x patch release, as recommended by the upstream [Docker docs](https://docs.requarks.io/install/docker).

### 2. Start Wiki.js

```bash
docker compose up -d
```

### 3. Verify Wiki.js is Running

```bash
docker compose ps
```

Both `wikijs` and `wikijs-db` should show as "healthy", and the setup wizard appears at
`http://localhost:3000/`.

### 4. Complete the Setup Wizard

Pick **PostgreSQL** as the database engine and enter the values from `.env`:

| Setting   | Value                |
| --------- | -------------------- |
| Host      | `db`                 |
| Port      | `5432`               |
| Username  | `WIKIJS_DB_USER`     |
| Password  | `WIKIJS_DB_PASSWORD` |
| Database  | `WIKIJS_DB_NAME`     |

> The host must be `db` (the compose service name), not `localhost`.

### 5. Stop the Stack

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Wiki.js start automatically, add `restart: unless-stopped` to the services.

## Data & Configuration

| Volume    | Container path               | Purpose                   |
| --------- | ---------------------------- | ------------------------- |
| `db_data` | `/var/lib/postgresql/data`   | PostgreSQL data files     |

| Host port (env)          | Container | Purpose      |
| ------------------------ | --------- | ------------ |
| `WIKIJS_PORT` (3000)     | 3000      | Web UI / API |

### Environment Variables

| Variable             | Required | Description                                        |
| -------------------- | -------- | -------------------------------------------------- |
| `WIKIJS_IMAGE`       | ❌       | Image tag (default `ghcr.io/requarks/wiki:2.5`)    |
| `POSTGRES_IMAGE`     | ❌       | DB image (default `postgres:15-alpine`)            |
| `WIKIJS_PORT`        | ❌       | Host port (default `3000`, maps to 3000)           |
| `WIKIJS_DB_NAME`     | ❌       | Database name (default `wiki`)                     |
| `WIKIJS_DB_USER`     | ❌       | Database user (default `wikijs`)                   |
| `WIKIJS_DB_PASSWORD` | ✅       | Database password — REQUIRED, app halts without it |
| `TZ`                 | ❌       | Container timezone (default `UTC`)                 |

## Updating

1. Back up the `db_data` volume (see [Production Considerations](#production-considerations)).
2. Bump `WIKIJS_IMAGE` in `.env` when a new release is out (watch
   [requarks/wiki releases](https://github.com/requarks/wiki/releases)).
3. Pull and recreate — migrations run automatically on startup:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. HTTPS

Put a reverse proxy ([Traefik](../traefik/), [Caddy](../caddy/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) in front of Wiki.js. Once proxied, consider
unpublishing the port and reaching Wiki.js only through the proxy network.

### 2. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so the stack comes back automatically
after a reboot or crash.

### 3. Protect the Database Password

`WIKIJS_DB_PASSWORD` in `.env` is stored in plain text — restrict the file permissions
(`chmod 600 .env`). On the server, generate a strong value with `openssl rand -hex 32`.

### 4. Backup the Database

`db_data` holds the entire wiki content (pages, revisions, attachments metadata). For a consistent
snapshot, stop the stack (`docker compose stop`), copy the volume, then start again. For easier
daily backups, switch `db_data` to the bind mount documented in `docker-compose.yml`.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` blocks in `docker-compose.yml`. Wiki.js + PostgreSQL are
light — 512M per service is a reasonable starting point.

## Troubleshooting

### Wiki.js stays unhealthy

```bash
docker compose logs wiki
```

The healthcheck needs a successful response from `http://localhost:3000/`. Common causes:
database not reachable (`DB_HOST` must be `db`) or wrong `WIKIJS_DB_*` credentials.

### PostgreSQL keeps restarting

`WIKIJS_DB_PASSWORD` must be set in `.env` — the postgres image refuses to start with an empty
password, and both services must read the same value (they do, from the same `.env`).

### Setup wizard page loads but can't connect to the DB

Double-check the wizard values match `.env` — especially Host (`db`) and the exact password.

### Port already in use

Change `WIKIJS_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f wiki

# Shell access
docker compose exec wiki /bin/sh

# Verify the web UI directly
curl -s http://localhost:3000/
```

## Resources

- [Wiki.js website](https://js.wiki/)
- [Wiki.js docs: Docker install](https://docs.requarks.io/install/docker)
- [Wiki.js releases](https://github.com/requarks/wiki/releases)
- [PostgreSQL image on Docker Hub](https://hub.docker.com/_/postgres)