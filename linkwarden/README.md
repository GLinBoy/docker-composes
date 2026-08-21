# Linkwarden

[Linkwarden](https://linkwarden.app/) is a self-hosted, open-source collaborative
bookmark manager. It lets you collect, organize, and preserve web links, pages, and
files — with built-in archiving so your bookmarks stay available even if the original
page goes down.

This stack runs the Linkwarden web app, a PostgreSQL database, and Meilisearch for
full-text search.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `NEXTAUTH_SECRET` - generate with `openssl rand -base64 32`
- `POSTGRES_PASSWORD` - generate with `openssl rand -hex 32`
- `MEILI_MASTER_KEY` - generate with `openssl rand -hex 32`

Optionally change:

- `LINKWARDEN_PORT` - the host port for the web UI (default `3000`)
- `NEXTAUTH_URL` - the public URL (must match the port if you change it)
- `LINKWARDEN_VERSION` - the exact Linkwarden version to run (defaults to `latest` when unset)

### 2. Start Linkwarden

```bash
docker compose up -d
```

### 3. Verify Linkwarden is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Create Your Account

Open http://localhost:3000 and follow the onboarding to create the admin account.

### 5. View Logs

```bash
docker compose logs -f linkwarden
```

### 6. Stop Linkwarden

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have Linkwarden start automatically, add `restart: unless-stopped`
> to each service.

## Configuration

### Environment Variables

| Variable                    | Required | Description                                                       |
| --------------------------- | -------- | ----------------------------------------------------------------- |
| `NEXTAUTH_SECRET`           | ✅       | NextAuth encryption secret                                        |
| `POSTGRES_PASSWORD`         | ✅       | PostgreSQL password                                               |
| `MEILI_MASTER_KEY`          | ✅       | Meilisearch master key (shared with Linkwarden)                   |
| `LINKWARDEN_VERSION`        | ❌       | Exact Linkwarden version (defaults to `latest` when unset)        |
| `LINKWARDEN_POSTGRES_IMAGE` | ❌       | PostgreSQL image (exact-pinned)                                   |
| `LINKWARDEN_MEILI_IMAGE`    | ❌       | Meilisearch image (exact-pinned)                                  |
| `LINKWARDEN_PORT`           | ❌       | Host port for the web UI (default: `3000`)                        |
| `NEXTAUTH_URL`              | ❌       | Public URL used by NextAuth (default: `http://localhost:3000/api/v1/auth`) |
| `POSTGRES_USER`             | ❌       | PostgreSQL user (default: `postgres`)                             |
| `POSTGRES_DB`               | ❌       | PostgreSQL database (default: `postgres`)                         |

### Volumes

| Volume          | Purpose                                     |
| --------------- | ------------------------------------------- |
| `data`          | Linkwarden uploads and archived files       |
| `postgres_data` | PostgreSQL database files                   |
| `meili_data`    | Meilisearch index data                      |

### Ports

| Port | Purpose           |
| ---- | ----------------- |
| 3000 | Linkwarden web UI |

## Updating

1. Bump `LINKWARDEN_VERSION` in `.env` to the next release (e.g. `v2.17.0`).
2. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

3. Linkwarden runs database migrations on startup — allow it to finish before using the app.

## Server Checklist

Before deploying to a production server:

- [ ] Generate a strong `NEXTAUTH_SECRET`, `POSTGRES_PASSWORD`, and `MEILI_MASTER_KEY`
- [ ] Set `NEXTAUTH_URL` to your real public URL (required when behind a reverse proxy)
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 3000
- [ ] Review the [setup guide](https://docs.linkwarden.app/self-hosting/setup) for backing up `data` and `postgres_data`
