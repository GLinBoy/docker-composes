# Dashy

[Dashy](https://dashy.to/) is a self-hosted, highly customizable dashboard for your homelab — it
organizes all your services into a single page from a simple `yaml` configuration file. This stack
runs the official [lissy93/dashy image](https://hub.docker.com/r/lissy93/dashy) with a named volume
for your configuration and a custom network.

The container runs as the non-root `node` user (uid/gid `1000`). The named volume is initialized
from the image's `/app/user-data` directory, so it is writable out of the box — config saves from
the UI work without any `user:` override.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port or timezone. The image is pinned to `4.7.17` by default
— bump `DASHY_VERSION` to update.

### 2. Start Dashy

```bash
docker compose up -d
```

On first start Dashy runs with its built-in default configuration. Your config and assets live in
the `dashy_data` volume, mounted at `/app/user-data` inside the container.

### 3. Verify Dashy is Running

```bash
docker compose ps
```

The `dashy` service should show as "healthy". The healthcheck runs Dashy's own
`/app/services/healthcheck.js` script against the default port `8080`.

### 4. Access the Web UI

Open `http://localhost:8080`. You can configure your dashboard entirely through the UI (the
"Edit Config" menu writes to `user-data/conf.yml`), or by editing the file directly:

```bash
docker compose exec dashy sh -c "vi /app/user-data/conf.yml"
```

Every file in `user-data` is served from Dashy's web root, so you can also drop in icons, custom
CSS, fonts and sub-config files there. If the `conf.yml` file is invalid, Dashy keeps a timestamped
copy under `user-data/config-backups/`.

### 5. Stop Dashy

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Dashy start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable               | Required | Description                                                                  |
| ---------------------- | -------- | ---------------------------------------------------------------------------- |
| `DASHY_VERSION`        | ❌       | Image tag (default `4.7.17`)                                                 |
| `DASHY_PORT`           | ❌       | Host port for the web UI (default `8080`, mapped to container 8080)          |
| `BASIC_AUTH_USERNAME`  | ❌       | Username for the optional static login on all server endpoints               |
| `BASIC_AUTH_PASSWORD`  | ❌       | Password for the optional static login (generate with `openssl rand -hex 32`) |
| `DASHY_TZ`             | ❌       | Container timezone (default `UTC`)                                           |

`BASIC_AUTH_USERNAME` / `BASIC_AUTH_PASSWORD` are commented out in `docker-compose.yml` and must be
uncommented there too, alongside setting them in `.env`.

### Volumes

| Volume                   | Purpose                                                              |
| ------------------------ | -------------------------------------------------------------------- |
| `dashy_data:/app/user-data` | Configuration (`conf.yml`), backups and custom assets              |

### Ports

| Port | Service | Access |
| ---- | ------- | ------ |
| 8080 | Dashy   | Web UI |

## Updating

1. Bump `DASHY_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Dashy starts automatically on boot
or failure.

### 2. Enable Authentication

Dashy exposes API endpoints for config saving, status/ping checks and a CORS proxy. Without auth
these are **open to anyone who can reach the port**. For a LAN-only instance that is usually fine;
before exposing Dashy to the internet, set `BASIC_AUTH_USERNAME` and `BASIC_AUTH_PASSWORD` (and
uncomment the matching lines in `docker-compose.yml`), or front it with an auth-aware reverse proxy.

### 3. Bind Mount for Config

Uncomment the bind mount in `docker-compose.yml` for easier management and backup of your
configuration:

```yaml
volumes:
  - /data/dashy:/app/user-data
```

If your host user is not uid 1000, either `chown -R 1000:1000 /data/dashy` or run the container as
your own user by adding `user: "$(id -u):$(id -g)"` to the service.

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 5. Reverse Proxy & TLS

Put Dashy behind one of the reverse-proxy stacks ([Caddy](../caddy/), [Traefik](../traefik/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) to get automatic TLS. Dashy exposes an
unauthenticated liveness endpoint at `/healthz` for proxy/load-balancer health checks.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs dashy
```

The healthcheck runs `/app/services/healthcheck.js`; a failure usually means Dashy is still
starting or the internal port was changed.

### Config changes have no effect

Dashy reads `user-data/conf.yml` at startup. Save changes through the UI, or restart the container
after editing the file directly. A malformed config is kept as-is and a backup is written to
`config-backups/`.

### Permission errors when saving config

The container runs as uid/gid `1000`. If you switched to a bind mount, make sure the mounted
directory is owned by `1000:1000` (or run the container as your own user).

### Port 8080 already in use

Change `DASHY_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f dashy

# Shell access
docker compose exec dashy sh

# Validate the config against Dashy's schema
docker compose exec dashy yarn validate-config

# Inspect the user-data volume (named volume)
docker run --rm -it -v dashy_dashy_data:/data alpine sh
```

## Resources

- [Dashy website](https://dashy.to/)
- [Dashy documentation](https://dashy.to/docs)
- [Dashy GitHub repository](https://github.com/Lissy93/dashy)
- [lissy93/dashy image on Docker Hub](https://hub.docker.com/r/lissy93/dashy)
