# Gitea

[Gitea](https://gitea.com/) is a painless, self-hosted, lightweight Git service. It provides Git
repositories, issue tracking, pull requests, package registry, CI/CD, wiki and a web UI, all in a
single binary. It is a community-managed fork of the original Gogs project.

This stack runs Gitea with **PostgreSQL 16** as its database. Gitea is the "server" role from the
[official image](https://hub.docker.com/r/gitea/gitea), backed by a dedicated Postgres container,
connected via a dedicated Docker network.

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

- `GITEA_VERSION` - the exact Gitea version to run (defaults to `latest` when unset)
- `POSTGRES_IMAGE` - the exact Postgres image (exact-pinned, never `latest`)
- `GITEA_HTTP_PORT` / `GITEA_SSH_PORT` - host port mappings
- `GITEA_UID` / `GITEA_GID` - the user/group owning the data volume
- `GITEA_TZ` - the timezone (default `UTC`)

### 2. Start the Stack

```bash
docker compose up -d
```

### 3. Verify the Stack is Running

```bash
docker compose ps
```

All services should show as "healthy". Gitea takes ~60s on first start — wait and re-run if it
shows "starting".

### 4. Complete the Onboarding

Open **http://localhost:3000** in your browser and follow the setup wizard to create the admin
account.

### 5. Verify the Services

```bash
# Gitea health endpoint — expect {"status":"ok"}
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

| Variable            | Required | Description                                                        |
| ------------------- | -------- | ------------------------------------------------------------------ |
| `POSTGRES_PASSWORD` | ✅       | Postgres password (`openssl rand -hex 32`)                         |
| `GITEA_VERSION`     | ❌       | Exact Gitea version (defaults to `latest` when unset)              |
| `POSTGRES_IMAGE`    | ❌       | Exact Postgres image (exact-pinned, never `latest`)                |
| `GITEA_HTTP_PORT`   | ❌       | Host port for the web UI (default: `3000`)                         |
| `GITEA_SSH_PORT`    | ❌       | Host port for SSH (default: `222`)                                 |
| `GITEA_UID`         | ❌       | User ID owning the data volume (default: `1000`)                   |
| `GITEA_GID`         | ❌       | Group ID owning the data volume (default: `1000`)                  |
| `GITEA_TZ`          | ❌       | Timezone (default: `UTC`)                                          |
| `POSTGRES_USER`     | ❌       | Postgres user (default: `gitea`)                                   |
| `POSTGRES_DB`       | ❌       | Postgres database (default: `gitea`)                               |

### Volumes

| Volume           | Purpose                                              |
| ---------------- | ---------------------------------------------------- |
| `gitea_data`     | Gitea config, repos and data (`/data`)               |
| `postgres_data`  | PostgreSQL data files (`/var/lib/postgresql/data`)   |

### Ports

| Port | Service       | Access              |
| ---- | ------------- | ------------------- |
| 3000 | Gitea web UI  | localhost by default |
| 222  | SSH           | git over SSH        |

### Gitea Configuration

Gitea is configured via `GITEA__<SECTION>__<KEY>` environment variables, which map directly to
entries in `app.ini` (e.g. `GITEA__server__DOMAIN`). See the
[configuration cheat sheet](https://docs.gitea.com/administration/config-cheat-sheet).

## Updating

1. Bump `GITEA_VERSION` in `.env` to the next release (e.g. `1.28.0`). Optionally bump
   `POSTGRES_IMAGE` too.
2. Pull and recreate the stack:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `POSTGRES_PASSWORD` in `.env` — never use the default
- [ ] Set `GITEA__server__ROOT_URL` / `GITEA__server__DOMAIN` to your actual domain
- [ ] Put Gitea behind a reverse proxy (Caddy/Nginx/Traefik) with HTTPS/TLS termination
- [ ] Firewall — only expose ports `3000` (or proxy-only) and `222` (SSH)
- [ ] Add `restart: unless-stopped` to both services if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Use bind mounts for `gitea_data` / `postgres_data` for easier backup control
- [ ] Back up both the Gitea data and PostgreSQL volumes regularly

## Resources

- [Gitea](https://gitea.com/)
- [Gitea documentation](https://docs.gitea.com/)
- [Gitea Docker image](https://hub.docker.com/r/gitea/gitea)
- [PostgreSQL Docker image](https://hub.docker.com/_/postgres)
