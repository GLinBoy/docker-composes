# Immich

[Immich](https://immich.app/) is a self-hosted photo and video management solution with an
open-source, high-performance, and ever-growing feature set. It lets you back up, organize,
search, and share your media from your own hardware.

This stack runs the Immich server, the machine-learning service (smart search, face
recognition, and object detection), a Valkey-backed Redis-compatible cache, and the
PostgreSQL database with vector-search extensions.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `DB_PASSWORD` - Generate with `openssl rand -hex 32` (letters and numbers only)

Optionally change:

- `UPLOAD_LOCATION` / `DB_DATA_LOCATION` - where media and database files are stored
- `IMMICH_PORT` - the host port for the web UI (default `2283`)
- `IMMICH_VERSION` - the exact Immich version to run (defaults to `latest` when unset)
- `IMMICH_DATABASE_IMAGE` / `IMMICH_REDIS_IMAGE` - the exact dependency images (release-locked to `IMMICH_VERSION`)

### 2. Start Immich

```bash
docker compose up -d
```

### 3. Verify Immich is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Create Your Account

Open http://localhost:2283 and follow the onboarding to create the admin account.

### 5. View Logs

```bash
docker compose logs -f immich-server
```

### 6. Stop Immich

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have Immich start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable                | Required | Description                                                   |
| ----------------------- | -------- | ------------------------------------------------------------- |
| `UPLOAD_LOCATION`       | ✅       | Host path where uploaded media is stored                      |
| `DB_DATA_LOCATION`      | ✅       | Host path where the PostgreSQL data is stored                 |
| `DB_PASSWORD`           | ✅       | Database password (letters/numbers only)                      |
| `DB_USERNAME`           | ✅       | Database username (default: `postgres`)                       |
| `DB_DATABASE_NAME`      | ✅       | Database name (default: `immich`)                             |
| `IMMICH_VERSION`        | ❌       | Exact Immich version to run (defaults to `latest` when unset) |
| `IMMICH_DATABASE_IMAGE` | ❌       | PostgreSQL image — release-locked to `IMMICH_VERSION`         |
| `IMMICH_REDIS_IMAGE`    | ❌       | Redis/Valkey image — release-locked to `IMMICH_VERSION`       |
| `IMMICH_PORT`           | ❌       | Host port for the web UI (default: `2283`)                    |
| `TZ`                    | ❌       | Timezone (default: `Etc/UTC`)                                 |

### Volumes

| Volume             | Purpose                                              |
| ------------------ | ---------------------------------------------------- |
| `UPLOAD_LOCATION`  | Uploaded photos, videos, and thumbnails (bind mount) |
| `DB_DATA_LOCATION` | PostgreSQL database files (bind mount)               |
| `model-cache`      | Machine-learning model cache (named volume)          |

### Ports

| Port | Purpose               |
| ---- | --------------------- |
| 2283 | Immich web UI and API |

## Updating

1. Bump `IMMICH_VERSION` in `.env` to the next release (e.g. `v3.2.0`).
2. Check the release's official `docker-compose.yml` and update `IMMICH_DATABASE_IMAGE` /
   `IMMICH_REDIS_IMAGE` if the pins changed — they are release-locked to `IMMICH_VERSION`
   and must not be bumped independently.
3. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

4. Immich may run one-time migrations on startup — allow it to finish before using the app.

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `DB_PASSWORD` in `.env` (`openssl rand -hex 32`)
- [ ] Point `UPLOAD_LOCATION` and `DB_DATA_LOCATION` at a fast, backed-up location (e.g. SSDs)
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 2283
- [ ] Review Immich's [backup and restore guide](https://immich.app/docs/administration/backup-and-restore) for media and database backups
- [ ] Optional: enable [machine-learning hardware acceleration](https://immich.app/docs/features/ml-hardware-acceleration) by appending e.g. `-cuda` to the `immich-machine-learning` image tag
