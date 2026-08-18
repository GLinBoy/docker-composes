# Forgejo

[Forgejo](https://forgejo.org/) is a self-hosted, lightweight software forge forges — a fork of
Gitea. It provides Git repositories, issue tracking, pull requests, package registry, CI/CD and a
web UI, all in a single binary. Easy to install and maintain, it scales from a single-user home
server to large organizations.

This stack runs Forgejo with **PostgreSQL 18** as its database. Forgejo is the "server" role from
the [official image](https://codeberg.org/forgejo/forgejo), backed by a dedicated Postgres
container, connected via a dedicated Docker network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `POSTGRES_PASSWORD` - a strong database password. Generate with:
  ```bash
  openssl rand -hex 32
  ```

Optionally change:

- `FORGEJO_VERSION` - the exact Forgejo version to run (defaults to `16.0.2` when unset; note:
  `codeberg.org` publishes only versioned tags, no `latest`)
- `POSTGRES_IMAGE` - the exact Postgres image (exact-pinned, never `latest`)
- `FORGEJO_HTTP_PORT` / `FORGEJO_SSH_PORT` - host port mappings
- `FORGEJO_UID` / `FORGEJO_GID` - the user/group owning the data volume
- `FORGEJO_TZ` - the timezone (default `UTC`)

### 2. Start the Stack

```bash
docker compose up -d
```

### 3. Verify the Stack is Running

```bash
docker compose ps
```

All services should show as "healthy". Forgejo takes ~60s on first start — wait and re-run if it
shows "starting".

### 4. Complete the Onboarding

Open **http://localhost:3000** in your browser and follow the setup wizard to create the admin
account.

### 5. Verify the Services

```bash
# Forgejo health endpoint — expect {"status":"pass"}
curl -sf http://localhost:3000/api/healthz

# SSH access
ssh -p 222 git@localhost
```

### 6. View Logs

```bash
docker compose logs -f server
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

| Variable           | Required | Description                                                       |
| ------------------ | -------- | ----------------------------------------------------------------- |
| `POSTGRES_PASSWORD`| ✅       | Postgres password (`openssl rand -hex 32`)                        |
| `FORGEJO_VERSION`  | ❌       | Exact Forgejo version (defaults to `16.0.2`; no `latest` on codeberg) |
| `POSTGRES_IMAGE`   | ❌       | Exact Postgres image (exact-pinned, never `latest`)               |
| `FORGEJO_HTTP_PORT`| ❌       | Host port for the web UI (default: `3000`)                        |
| `FORGEJO_SSH_PORT` | ❌       | Host port for SSH (default: `222`)                                |
| `FORGEJO_UID`      | ❌       | User ID owning the data volume (default: `1000`)                  |
| `FORGEJO_GID`      | ❌       | Group ID owning the data volume (default: `1000`)                 |
| `FORGEJO_TZ`       | ❌       | Timezone (default: `UTC`)                                         |
| `POSTGRES_USER`    | ❌       | Postgres user (default: `forgejo`)                                |
| `POSTGRES_DB`      | ❌       | Postgres database (default: `forgejo`)                            |

### Volumes

| Volume           | Purpose                                              |
| ---------------- | ---------------------------------------------------- |
| `forgejo_data`   | Forgejo config, repos and data (`/data`)             |
| `postgres_data`  | PostgreSQL data files (`/var/lib/postgresql`)        |

> Postgres 18+ stores data in `/var/lib/postgresql/<major>/data`. The volume mounts the parent
> directory so `pg_upgrade --link` works across major upgrades.

### Ports

| Port | Service        | Access              |
| ---- | -------------- | ------------------- |
| 3000 | Forgejo web UI | localhost by default |
| 222  | SSH            | git over SSH        |

### Forgejo Configuration

Forgejo is configured via `FORGEJO__<SECTION>__<KEY>` environment variables, which map directly to
entries in `app.ini` (e.g. `FORGEJO__server__DOMAIN`). See the
[configuration cheat sheet](https://forgejo.org/docs/latest/admin/config-cheat-sheet/).

## Updating

1. Bump `FORGEJO_VERSION` in `.env` to the next release (e.g. `16.1.0`). Optionally bump
   `POSTGRES_IMAGE` too.
2. Pull and recreate the stack:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `POSTGRES_PASSWORD` in `.env` — never use the default
- [ ] Set `FORGEJO__server__ROOT_URL` / `FORGEJO__server__DOMAIN` to your actual domain
- [ ] Put Forgejo behind a reverse proxy (Caddy/Nginx/Traefik) with HTTPS/TLS termination
- [ ] Firewall — only expose ports `3000` (or proxy-only) and `222` (SSH)
- [ ] Add `restart: unless-stopped` to both services if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Use bind mounts for `forgejo_data` / `postgres_data` for easier backup control
- [ ] Back up both the Forgejo data and PostgreSQL volumes regularly

## Resources

- [Forgejo](https://forgejo.org/)
- [Forgejo documentation](https://forgejo.org/docs/latest/)
- [Forgejo Docker image](https://codeberg.org/forgejo/forgejo)
- [PostgreSQL Docker image](https://hub.docker.com/_/postgres)
