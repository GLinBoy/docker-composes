# Mattermost

[Mattermost](https://mattermost.com/) is a self-hosted, open-source alternative to proprietary
SaaS messaging. It provides workplace messaging across web, PC, and phones with archiving, search,
and integration with your existing systems.

This stack runs **Mattermost Server** (`mattermost/mattermost-enterprise-edition`) with a dedicated
**PostgreSQL** database. Mattermost uses the database for metadata and its local filesystem for file
uploads and search (Bleve) indexes, all on named volumes.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `POSTGRES_PASSWORD` — generate with `openssl rand -hex 32`
- `MATTERMOST_SITE_URL` — set to your real domain (e.g. `https://chat.example.com`) if you will
  expose Mattermost beyond localhost

### 2. Start Mattermost

```bash
docker compose up -d
```

### 3. Verify Mattermost is Running

```bash
docker compose ps
```

Both services should show as "healthy". On first start, Mattermost runs its database migrations and
may take a minute or two before the `mattermost` container reports healthy.

### 4. Access the Web UI

Open http://localhost:8065 in your browser and create the first System Admin account.

### 5. Stop Mattermost

```bash
docker compose down
# Remove the named volumes too (loses all data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                    | Required | Description                                                           |
| --------------------------- | -------- | --------------------------------------------------------------------- |
| `MATTERMOST_IMAGE`          | ❌       | Image tag (default `mattermost/mattermost-enterprise-edition:11.7.0`) |
| `MATTERMOST_POSTGRES_IMAGE` | ❌       | PostgreSQL image (default `postgres:18-alpine`)                       |
| `POSTGRES_PASSWORD`         | ✅       | PostgreSQL password (generate with `openssl rand -hex 32`)            |
| `POSTGRES_USER`             | ❌       | Database user (default `mmuser`)                                      |
| `POSTGRES_DB`               | ❌       | Database name (default `mattermost`)                                  |
| `MATTERMOST_PORT`           | ❌       | Host port for the web UI (default `8065`)                             |
| `MATTERMOST_SITE_URL`       | ❌       | Public site URL (default `http://localhost:8065`)                     |
| `MATTERMOST_TZ`             | ❌       | Container timezone (default `UTC`)                                    |

Mattermost is configured through `MM_*` environment variables in `docker-compose.yml`. Variables set
via the environment take precedence over `config.json` (and appear greyed out in the System Console).
Add any additional `MM_*` setting to both `docker-compose.yml` and `.env.example` if you need it.

### Volumes

| Volume                      | Purpose                                |
| --------------------------- | -------------------------------------- |
| `mattermost-config`         | `config.json` and server configuration |
| `mattermost-data`           | File uploads and attachments           |
| `mattermost-logs`           | Server logs                            |
| `mattermost-plugins`        | Installed server plugins               |
| `mattermost-client-plugins` | Client-side plugins (web app bundles)  |
| `mattermost-bleve-indexes`  | Local (Bleve) search index             |
| `mattermost-postgres`       | PostgreSQL data files                  |

### Ports

| Port | Service               | Access               |
| ---- | --------------------- | -------------------- |
| 8065 | Mattermost web UI/API | localhost by default |

## Production Considerations

### 1. Set the Site URL

Before exposing Mattermost, set `MATTERMOST_SITE_URL` in `.env` to your real public URL. If you change
it later, update it in **System Console → Environment → Web Server** and restart, then set it again
in the System Console so Mattermost can re-register its credentials.

### 2. Reverse Proxy and TLS

Mattermost serves plain HTTP on 8065. For production, put it behind a reverse proxy (Caddy, Nginx,
Traefik) with TLS and set the proxy headers so the client IP/URL are forwarded. Example Nginx block:

```nginx
location / {
    proxy_pass http://mattermost:8065;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
}
```

### 3. Bind Mounts for Data

Named volumes are used by default. For easier backup control, uncomment the bind mounts in
`docker-compose.yml`:

```yaml
volumes:
  - /data/mattermost/data:/mattermost/data
```

The container runs as UID/GID **2000** — if you switch to bind mounts, ensure the host directories
are writable by that user (`sudo chown -R 2000:2000 /data/mattermost`).

### 4. Resource Limits

Uncomment and tune the `deploy.resources` blocks in `docker-compose.yml`. Mattermost recommends
sizing memory based on your deployment size (see the
[Mattermost scaling docs](https://docs.mattermost.com/administration-guide/scale/scaling-for-enterprise.html)).

### 5. Local Mode (used by the healthcheck)

The image sets `MM_SERVICESETTINGS_ENABLELOCALMODE=true`, which lets the built-in `mmctl` healthcheck
(`mmctl system status --local`) talk to the server over a unix socket. Keep it enabled for the
healthcheck to work.

### 6. Optional: S3-compatible object storage

For large deployments, store files in an S3-compatible service (MinIO, AWS S3, etc.) instead of the
local `/mattermost/data` volume. Configure it in **System Console → Environment → File Storage**.

## Troubleshooting

### Container stays unhealthy

Check the logs:

```bash
docker compose logs mattermost
```

Common issues:

- First start is slow (DB migrations) — give it a few minutes
- `POSTGRES_PASSWORD` mismatch between `mattermost` and `postgres` — reset it in `.env` and
  `docker compose down -v` (data loss) or recreate the `postgres` volume
- Port `8065` already in use — change `MATTERMOST_PORT` in `.env`

### Healthcheck fails only in this stack

The healthcheck mirrors the image's built-in check:

```yaml
test: ["CMD", "/mattermost/bin/mmctl", "system", "status", "--local"]
```

It requires Local Mode (enabled by default in the image). If you disabled
`MM_SERVICESETTINGS_ENABLELOCALMODE`, the check will fail — re-enable it or replace the healthcheck.

### Volume permission errors with bind mounts

The container runs as UID/GID 2000. Fix ownership on the host:

```bash
sudo chown -R 2000:2000 /data/mattermost
```

### Reset Mattermost

Remove the named volumes and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f mattermost

# Shell-free status via mmctl (image is distroless — no shell)
docker compose exec mattermost /mattermost/bin/mmctl system status --local

# Upgrade to a newer Mattermost version
# Bump MATTERMOST_IMAGE in .env, then:
docker compose pull mattermost
docker compose up -d

# Reset everything (loses all data)
docker compose down -v
```
