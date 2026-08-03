# Forgejo — Docker Compose Setup

A production-oriented [Forgejo](https://forgejo.org/) stack using Docker Compose, pinned to version **16.0.2**, backed by **PostgreSQL 18**. Designed to run out-of-the-box locally with clear inline comments guiding every change needed for a production server deployment.

---

## Stack Overview

| Service    | Image                                 | Port(s)                    |
| ---------- | ------------------------------------- | -------------------------- |
| Forgejo    | `codeberg.org/forgejo/forgejo:16.0.2` | `3000` (HTTP), `222` (SSH) |
| PostgreSQL | `postgres:18.4-alpine3.23`            | (internal only)            |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) >= 24.x
- [Docker Compose](https://docs.docker.com/compose/) >= v2.x (included with Docker Desktop)

---

## Files

```
forgejo/
├── docker-compose.yml   # Main compose file
├── .env.example         # Template for environment variables
└── README.md            # This file
```

---

## Quick Start

### 1. Create the environment file

```bash
cd forgejo/
cp .env.example .env
```

Then edit `.env` and set a strong `POSTGRES_PASSWORD`:

```bash
# generate one with: openssl rand -hex 32
POSTGRES_PASSWORD=changeme
```

### 2. Start the stack

```bash
docker compose up -d
```

### 3. Initialize Forgejo

Open **http://localhost:3000** in your browser and complete the onboarding (create the admin account).

---

## Verifying the Services

### Check all container health statuses

```bash
docker compose ps
```

All services should show `healthy`. Forgejo takes ~60s on first start — wait and re-run if it shows `starting`.

### Forgejo

```bash
# Health endpoint — expect {"status":"ok"}
curl -sf http://localhost:3000/api/healthz

# SSH access
ssh -p 222 git@localhost
```

### PostgreSQL

```bash
docker compose exec db pg_isready -U forgejo -d forgejo
```

---

## Stop / Reset

```bash
docker compose down     # stop the stack, keep all data
docker compose down -v  # full reset — deletes ALL Forgejo and PostgreSQL data
```

---

## Configuration

Forgejo is configured via `FORGEJO__<SECTION>__<KEY>` environment variables, which map directly to entries in `app.ini` (e.g. `FORGEJO__server__DOMAIN`). See the [configuration cheat sheet](https://forgejo.org/docs/latest/admin/config-cheat-sheet/).

---

## Production Considerations

Before deploying to production:

1. **Set a strong database password** in `.env` — never use the default. Generate with `openssl rand -hex 32`.
2. **Backup the data** — use bind mounts for easier backup control (see the `# SERVER:` comments in `docker-compose.yml`), and back up both the Forgejo data and PostgreSQL volumes. Note: with Postgres 18+ the data lives in the `postgres_data` volume at `/var/lib/postgresql/18/data`.
3. **Resource limits** — uncomment the `deploy.resources` block in `docker-compose.yml` and adjust CPU/memory based on expected traffic.
4. **Reverse proxy + HTTPS** — put Forgejo behind a reverse proxy (e.g. Caddy, Traefik, Nginx Proxy Manager) and set `FORGEJO__server__ROOT_URL` / `FORGEJO__server__DOMAIN` accordingly.
5. **Firewall** — only expose ports `3000` (HTTP, or proxy-only) and `222` (SSH) on your server.
6. **Restart policy** — this stack deliberately sets **no** restart policy, so containers stop when the host reboots (saves resources). Add `restart: unless-stopped` to both services only if you want them to auto-start.
