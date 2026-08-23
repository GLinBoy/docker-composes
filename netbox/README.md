# NetBox

[NetBox](https://netbox.dev/) is an open-source infrastructure resource modeling (IRM) and
DCIM/IPAM solution for managing data center and network infrastructure. It provides IP
address management (IPAM), data center infrastructure management (DCIM), rack elevation
views, cable connections, power connections, and much more — all through a web UI and a
REST API.

This stack runs the official
[`netboxcommunity/netbox` image](https://hub.docker.com/r/netboxcommunity/netbox), backed by
PostgreSQL and two Valkey (Redis-compatible) instances — one for the worker queue and one for
the cache — plus a background worker for async tasks (webhooks, reports, scripts).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `NETBOX_SECRET_KEY` - Django secret key, generate with `openssl rand -hex 50`
- `NETBOX_DB_PASSWORD` - database password
- `NETBOX_REDIS_PASSWORD` / `NETBOX_REDIS_CACHE_PASSWORD` - two different Redis passwords
- `NETBOX_SUPERUSER_EMAIL` / `NETBOX_SUPERUSER_PASSWORD` - set these and `NETBOX_SKIP_SUPERUSER=false` to auto-create the admin on first start

Optionally change:

- `NETBOX_PORT` - the host port for the web UI (default `8000`)
- `NETBOX_VERSION` - the exact image tag to run (defaults to `latest` when unset)
- `NETBOX_DB_IMAGE` / `NETBOX_REDIS_IMAGE` - the exact dependency images

### 2. Start NetBox

```bash
docker compose up -d
```

### 3. Verify NetBox is Running

```bash
docker compose ps
```

All services should show as "healthy". First start applies database migrations, which can
take a few minutes — the `netbox` service healthcheck allows up to 90s.

### 4. Create the Superuser

If you didn't set `NETBOX_SKIP_SUPERUSER=false`, create the admin account manually:

```bash
docker compose exec netbox /opt/netbox/netbox/manage.py createsuperuser
```

### 5. Access the Web UI

Open `http://localhost:8000` and log in with the superuser you created.

### 6. Stop NetBox

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have NetBox start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable                          | Required | Description                                                          |
| --------------------------------- | -------- | -------------------------------------------------------------------- |
| `NETBOX_VERSION`                  | ❌       | Exact image tag (default `netboxcommunity/netbox:latest` when unset) |
| `NETBOX_DB_IMAGE`                 | ❌       | PostgreSQL image (default `docker.io/postgres:17.11-alpine`)         |
| `NETBOX_REDIS_IMAGE`              | ❌       | Valkey image (default `docker.io/valkey/valkey:8.1-alpine`)          |
| `TZ`                              | ❌       | Timezone (default `Etc/UTC`)                                         |
| `NETBOX_PORT`                     | ❌       | Host port for the web UI (default `8000`, container fixed to 8080)   |
| `NETBOX_SECRET_KEY`               | ✅       | Django secret key (`openssl rand -hex 50`)                           |
| `NETBOX_SKIP_SUPERUSER`           | ❌       | Skip auto superuser creation (default `true`)                        |
| `NETBOX_SUPERUSER_EMAIL`          | ❌       | Admin email (used when `NETBOX_SKIP_SUPERUSER=false`)                |
| `NETBOX_SUPERUSER_PASSWORD`       | ❌       | Admin password (used when `NETBOX_SKIP_SUPERUSER=false`)             |
| `NETBOX_SUPERUSER_API_TOKEN`      | ❌       | Admin API token (used when `NETBOX_SKIP_SUPERUSER=false`)            |
| `NETBOX_DB_NAME`                  | ❌       | Database name (default `netbox`)                                     |
| `NETBOX_DB_USER`                  | ❌       | Database user (default `netbox`)                                     |
| `NETBOX_DB_PASSWORD`              | ✅       | Database password (`openssl rand -hex 24`)                           |
| `NETBOX_REDIS_PASSWORD`           | ✅       | Main Redis password (`openssl rand -hex 24`)                         |
| `NETBOX_REDIS_CACHE_PASSWORD`     | ✅       | Cache Redis password — different value (`openssl rand -hex 24`)      |
| `NETBOX_GRAPHQL_ENABLED`          | ❌       | Enable the GraphQL API (default `true`)                              |
| `NETBOX_METRICS_ENABLED`          | ❌       | Enable Prometheus metrics endpoint (default `false`)                 |
| `NETBOX_WEBHOOKS_ENABLED`         | ❌       | Enable webhooks (default `true`)                                     |
| `NETBOX_CORS_ORIGIN_ALLOW_ALL`    | ❌       | Allow all CORS origins (default `false`)                             |
| `NETBOX_API_TOKEN_PEPPER_1`       | ❌       | Pepper for API token hashing (`openssl rand -hex 24`)                |
| `NETBOX_RELEASE_CHECK_URL`        | ❌       | Release check URL used by the version banner                         |
| `NETBOX_EMAIL_SERVER`             | ❌       | SMTP server (default `localhost`)                                    |
| `NETBOX_EMAIL_PORT`               | ❌       | SMTP port (default `25`)                                             |
| `NETBOX_EMAIL_USERNAME`           | ❌       | SMTP username (default `netbox`)                                     |
| `NETBOX_EMAIL_PASSWORD`           | ❌       | SMTP password                                                        |
| `NETBOX_EMAIL_USE_SSL` / `NETBOX_EMAIL_USE_TLS` | ❌ | SMTP encryption (default `false`, mutually exclusive)        |
| `NETBOX_EMAIL_TIMEOUT`            | ❌       | SMTP timeout in seconds (default `5`)                                |
| `NETBOX_EMAIL_FROM`               | ❌       | From address for emails (default `netbox@localhost`)                 |

### Volumes

| Volume                   | Purpose                                 |
| ------------------------ | --------------------------------------- |
| `netbox_media_files`     | Uploaded images, attachments, and media |
| `netbox_reports_files`   | User-uploaded reports                   |
| `netbox_scripts_files`   | User-uploaded scripts                   |
| `netbox_postgres_data`   | PostgreSQL database files               |
| `netbox_redis_data`      | Main Redis (queue) data                 |
| `netbox_redis_cache_data`| Cache Redis data                        |

### Ports

| Port | Purpose                    |
| ---- | -------------------------- |
| 8000 | NetBox web UI and REST API |

The port is bound to `127.0.0.1` only by default. See the server checklist below before
exposing it publicly.

## Updating

1. Check the [NetBox releases page](https://github.com/netbox-community/netbox/releases) and
   the matching [netbox-docker releases page](https://github.com/netbox-community/netbox-docker/releases).
   The image tag format is `<netbox-version>-<netbox-docker-version>`, e.g. `v4.6.8-5.0.2`.
2. Bump `NETBOX_VERSION` in `.env` to the next tag.
3. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

4. NetBox runs migrations automatically on startup — allow it to finish before using the app.

> Do NOT bump `NETBOX_DB_IMAGE` / `NETBOX_REDIS_IMAGE` independently; keep them at the pinned
> versions in `.env.example` unless a NetBox release requires newer dependency images.

## Server Checklist

Before deploying to a production server:

- [ ] Set strong secrets in `.env`: `NETBOX_SECRET_KEY` (`openssl rand -hex 50`), `NETBOX_DB_PASSWORD`, `NETBOX_REDIS_PASSWORD`, `NETBOX_REDIS_CACHE_PASSWORD`, `NETBOX_API_TOKEN_PEPPER_1`
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Keep NetBox behind a reverse proxy (e.g. [Caddy](../caddy/), [Nginx](../nginx/), [Traefik](../traefik/)) instead of exposing port 8000
- [ ] Set the `NETBOX_EMAIL_*` variables to a real SMTP server so password resets work
- [ ] Back up the `netbox_postgres_data` volume (or use a bind mount) — this holds all NetBox data
- [ ] Read the upstream [netbox-docker wiki](https://github.com/netbox-community/netbox-docker/wiki) for LDAP, plugins, and advanced configuration

## Custom Configuration

NetBox reads its settings from environment variables by default. For settings that can't be
configured via environment variables (plugins, LDAP, banner, etc.), mount a directory with
custom `configuration.py` / `extra.py` files:

```yaml
services:
  netbox:
    volumes:
      - ./configuration:/etc/netbox/config:ro
```

See the [upstream configuration files](https://github.com/netbox-community/netbox-docker/tree/release/configuration)
for examples.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs netbox
```

The healthcheck requests `http://localhost:8080/login/`. On first start the container spends
time applying database migrations — wait and re-check with `docker compose ps`.

### Migrations fail or DB connection errors

Make sure `NETBOX_DB_PASSWORD` matches in both `NETBOX_DB_PASSWORD` (NetBox) and the
`POSTGRES_PASSWORD` passed to the `postgres` service (they share the same variable). Also
verify `NETBOX_REDIS_PASSWORD` and `NETBOX_REDIS_CACHE_PASSWORD` are set to two **different**
values.

### Port 8000 already in use

Change `NETBOX_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f netbox

# Shell access
docker exec -it netbox /bin/bash

# NetBox management commands
docker compose exec netbox /opt/netbox/netbox/manage.py shell

# API health check
curl -sf http://localhost:8000/api/ | head
```

## Resources

- [NetBox website](https://netbox.dev/)
- [NetBox documentation](https://docs.netbox.dev/)
- [netbox-docker GitHub repository](https://github.com/netbox-community/netbox-docker)
- [netbox-docker wiki](https://github.com/netbox-community/netbox-docker/wiki)
- [netboxcommunity/netbox image on Docker Hub](https://hub.docker.com/r/netboxcommunity/netbox)
