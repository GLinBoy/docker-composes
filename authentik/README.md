# authentik

[authentik](https://goauthentik.io) is an open-source identity provider (IdP) and single
sign-on (SSO) solution. It provides authentication, MFA, user management, application access
control, proxy/LDAP outposts, and more through a fully self-hosted web UI and API.

This stack runs the official `ghcr.io/goauthentik/server` image as separate `server` and `worker`
services, backed by **PostgreSQL 16** and **Redis 7**, on a custom network with named volumes for
media, custom templates, certificates, and GeoIP data.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `AUTHENTIK_SECRET_KEY` — generate with `openssl rand -base64 60 | tr -d '\n'`
- `PG_PASS` — generate with `openssl rand -base64 36 | tr -d '\n'` (PostgreSQL passwords must be
  99 characters or fewer)

The app image is pinned to `ghcr.io/goauthentik/server:2026.5.6` by default — bump
`AUTHENTIK_VERSION` to update.

### 2. Start authentik

```bash
docker compose up -d
```

The `server` and `worker` services wait for `postgresql` and `redis` to become healthy before
starting. On first start, authentik applies database migrations — this can take a few minutes.

### 3. Verify authentik is Running

```bash
docker compose ps
```

All four services should show as "healthy". The healthcheck uses the image's built-in `ak
healthcheck` command (it probes `/-/health/live/` over the container's unix socket), because the
image ships without a shell, `curl`, or `wget`.

### 4. Complete Initial Setup

Browse to <http://localhost:9000> — you'll be prompted to create the `akadmin` user (the default
administrator account).

### 5. Stop authentik

```bash
docker compose down
# Remove the named volumes too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                             | Required | Description                                          |
| ------------------------------------ | -------- | ---------------------------------------------------- |
| `AUTHENTIK_VERSION`                  | ❌       | App image tag (default `2026.5.6`)                   |
| `AUTHENTIK_SECRET_KEY`               | ✅       | Secret key used to encrypt/sign data                 |
| `PG_PASS`                            | ✅       | PostgreSQL password                                  |
| `PG_USER`                            | ❌       | PostgreSQL user (default `authentik`)                |
| `PG_DB`                              | ❌       | PostgreSQL database name (default `authentik`)       |
| `AUTHENTIK_POSTGRES_IMAGE`           | ❌       | PostgreSQL image (default `postgres:16-alpine`)      |
| `AUTHENTIK_REDIS_IMAGE`              | ❌       | Redis image (default `redis:7-alpine`)               |
| `AUTHENTIK_PORT_HTTP`                | ❌       | Host port for HTTP (default `9000`)                  |
| `AUTHENTIK_PORT_HTTPS`               | ❌       | Host port for HTTPS (default `9443`)                 |
| `AUTHENTIK_LOG_LEVEL`                | ❌       | Log level: debug/info/warning/error (default `info`) |
| `AUTHENTIK_ERROR_REPORTING__ENABLED` | ❌       | Send error reports to authentik (default `false`)    |
| `AUTHENTIK_TZ`                       | ❌       | Timezone — keep `UTC` (default `UTC`)                |

### Volumes

| Volume                              | Purpose                            |
| ----------------------------------- | ---------------------------------- |
| `database:/var/lib/postgresql/data` | PostgreSQL data                    |
| `redis:/data`                       | Redis persistence (cache/sessions) |
| `media:/media`                      | User-uploaded media and files      |
| `custom-templates:/templates`       | Custom email/template overrides    |
| `certs:/certs`                      | Certificates (brands, outposts)    |
| `geoip:/geoip`                      | MaxMind GeoIP databases            |

### Ports

| Port | Service        | Access               |
| ---- | -------------- | -------------------- |
| 9000 | Web UI (HTTP)  | localhost by default |
| 9443 | Web UI (HTTPS) | localhost by default |

## Usage Notes

- **First run**: <http://localhost:9000> → create the `akadmin` user and complete the wizard.
- **Time zone**: All internal operations run in UTC. Keep `AUTHENTIK_TZ=UTC` and do **not** mount
  `/etc/localtime` or `/etc/timezone` into the containers — it breaks OAuth/SAML (see the
  [authentik docs](https://docs.goauthentik.io/docs/install-config/install/docker-compose)).
- **Reverse proxy**: For production, terminate TLS with a reverse proxy (Caddy, Traefik, nginx) in
  front of port `9000`/`9443`.

## Production Considerations

### 1. Strong Secrets

Never use empty/default secrets in production. Generate fresh ones:

```bash
openssl rand -base64 60 | tr -d '\n'   # AUTHENTIK_SECRET_KEY
openssl rand -base64 36 | tr -d '\n'   # PG_PASS
```

### 2. Resource Limits

Uncomment and tune the `deploy.resources` blocks in `docker-compose.yml` — authentik recommends at
least 2 CPU cores and 2 GB of RAM.

### 3. Bind Mounts for Data

Prefer bind mounts over named volumes for easier backup:

```yaml
volumes:
  - /data/authentik/database:/var/lib/postgresql/data
  - /data/authentik/media:/media
```

### 4. Outposts (auto-deployment)

By default this stack runs the `worker` as the image's non-root user (UID 1000) and does **not**
mount the Docker socket. To let authentik automatically deploy and manage proxy/LDAP outpost
containers, mount the Docker socket on the `worker` service:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

The official compose also runs the `worker` with `user: root` so it can fix socket/media
permissions; this stack omits that for security. Mounting the Docker socket gives the container
control over the host Docker daemon — prefer a
[Docker socket proxy](https://docs.goauthentik.io/docs/add-secure-apps/outposts/integrations/docker#docker-socket-proxy)
when possible.

### 5. Backups

Back up at least the `database`, `media`, and `certs` volumes. A PostgreSQL dump is the safest
method:

```bash
docker compose exec postgresql pg_dump -U ${PG_USER:-authentik} ${PG_DB:-authentik} > authentik.sql
```

## Troubleshooting

### Containers stay "unhealthy" on first start

First boot applies migrations and can take a few minutes. Check the logs:

```bash
docker compose logs server
docker compose logs worker
```

### Can't reach the initial setup flow

Confirm the server is healthy and the port mapping is correct:

```bash
docker compose ps
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:9000/if/flow/initial-setup/
```

See the [authentik troubleshooting docs](https://docs.goauthentik.io/docs/troubleshooting/).

### Reset the stack

```bash
docker compose down -v
docker compose up -d
```
