# Gogs

[Gogs](https://gogs.io/) is a painless, self-hosted Git service written in Go. It provides Git
repositories, issue tracking, pull requests, wiki and a web UI, all in a single binary. It is
designed for small teams and is one of the lightest self-hosted Git forges available.

This stack runs the [official Gogs image](https://hub.docker.com/r/gogs/gogs). Gogs uses embedded
**SQLite** by default; the stack also ships a **PostgreSQL 16** container that you can select in the
setup wizard if you prefer a dedicated database. Both are connected via a dedicated Docker network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

By default no secrets are needed. Optionally change:

- `GOGS_VERSION` - the exact Gogs version to run (defaults to `latest` when unset)
- `POSTGRES_IMAGE` - the exact Postgres image (exact-pinned, never `latest`)
- `GOGS_HTTP_PORT` / `GOGS_SSH_PORT` - host port mappings
- `GOGS_TZ` - the timezone (default `UTC`)

### 2. Start the Stack

```bash
docker compose up -d
```

### 3. Verify the Stack is Running

```bash
docker compose ps
```

All services should show as "healthy". Gogs takes ~60s on first start — wait and re-run if it shows
"starting".

### 4. Complete the Onboarding

Open **http://localhost:3000** in your browser and follow the setup wizard. By default Gogs uses
embedded SQLite — no database configuration is needed. To use the bundled Postgres instead, select
**PostgreSQL** in the wizard with host `postgresql`, port `5432`, and the credentials from `.env`.

### 5. Verify the Services

```bash
# Gogs responds
curl -sf http://localhost:3000/

# SSH access
ssh -p 22 git@localhost
```

### 6. View Logs

```bash
docker compose logs -f gogs
```

### 7. Stop the Stack

```bash
docker compose down
# Remove data volumes too (full reset):
docker compose down -v
```

> Containers stop when the host restarts (no restart policy is set, per repository convention). To
> have the stack start automatically, uncomment `restart: unless-stopped` on each service.

## Configuration

### Environment Variables

| Variable            | Required | Description                                                        |
| ------------------- | -------- | ------------------------------------------------------------------ |
| `GOGS_VERSION`      | ❌       | Exact Gogs version (defaults to `latest` when unset)               |
| `POSTGRES_IMAGE`    | ❌       | Exact Postgres image (exact-pinned, never `latest`)                |
| `GOGS_HTTP_PORT`    | ❌       | Host port for the web UI (default: `3000`)                         |
| `GOGS_SSH_PORT`     | ❌       | Host port for SSH (default: `22`)                                  |
| `GOGS_TZ`           | ❌       | Timezone (default: `UTC`)                                          |
| `POSTGRES_USER`     | ❌       | Postgres user (default: `gogs`) — optional (SQLite is default)     |
| `POSTGRES_PASSWORD` | ❌       | Postgres password — optional (SQLite is default)                   |
| `POSTGRES_DB`       | ❌       | Postgres database (default: `gogs`) — optional (SQLite is default) |

### Volumes

| Volume          | Purpose                                              |
| --------------- | ---------------------------------------------------- |
| `gogs_data`     | Gogs config, repos and data (`/data`)                |
| `postgres_data` | PostgreSQL data files (`/var/lib/postgresql/data`)   |

### Ports

| Port | Service       | Access              |
| ---- | ------------- | ------------------- |
| 3000 | Gogs web UI   | localhost by default |
| 22   | SSH           | git over SSH        |

## Updating

1. Bump `GOGS_VERSION` in `.env` to the next release (e.g. `0.15.0`). Optionally bump
   `POSTGRES_IMAGE` too.
2. Pull and recreate the stack:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Put Gogs behind a reverse proxy (Caddy/Nginx/Traefik) with HTTPS/TLS termination
- [ ] Firewall — only expose ports `3000` (or proxy-only) and `22` (SSH)
- [ ] If using Postgres, set a strong `POSTGRES_PASSWORD` and configure it in the setup wizard
- [ ] Add `restart: unless-stopped` to both services if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Use bind mounts for `gogs_data` / `postgres_data` for easier backup control
- [ ] Back up the Gogs data directory (and PostgreSQL volume if used) regularly

## Resources

- [Gogs](https://gogs.io/)
- [Gogs documentation](https://gogs.io/docs)
- [Gogs Docker image](https://hub.docker.com/r/gogs/gogs)
- [PostgreSQL Docker image](https://hub.docker.com/_/postgres)
