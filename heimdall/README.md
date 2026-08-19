# Heimdall

[Heimdall](https://heimdall.site) is an elegant way to organise all of your application links — a
dashboard that acts as a home page / start page for your most-used web apps and sites. It includes
a search bar (Google, Bing, or DuckDuckGo) and a built-in theme/icon support. This stack runs the
official [linuxserver.io image](https://docs.linuxserver.io/images/docker-heimdall/) (Alpine-based)
with a named volume for persistent configuration and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the ports, timezone, or user/group IDs. The image is pinned to
`linuxserver/heimdall:2.8.1` by default — bump `HEIMDALL_VERSION` to update.

### 2. Start Heimdall

```bash
docker compose up -d
```

### 3. Verify Heimdall is Running

```bash
docker compose ps
```

The `heimdall` service should show as "healthy".

### 4. Access the Web UI

Open `http://localhost` (or `https://localhost`). Follow the on-screen setup to create your first
dashboard tiles.

### 5. Stop Heimdall

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Heimdall start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable                    | Required | Description                                                                 |
| --------------------------- | -------- | --------------------------------------------------------------------------- |
| `HEIMDALL_VERSION`          | ❌       | Image tag (default `linuxserver/heimdall:2.8.1`)                            |
| `HEIMDALL_HTTP_PORT`        | ❌       | Host port for HTTP (default `80`, mapped to container 80)                   |
| `HEIMDALL_HTTPS_PORT`       | ❌       | Host port for HTTPS (default `443`, mapped to container 443)                |
| `PUID` / `PGID`             | ❌       | User/group ID the container runs as (default `1000`/`1000`)                 |
| `HEIMDALL_TZ`               | ❌       | Container timezone (default `UTC`)                                          |
| `ALLOW_INTERNAL_REQUESTS`   | ❌       | Allow lookups to private/reserved IPs (default `false`)                     |

### Volumes

| Volume                   | Purpose                                |
| ------------------------ | -------------------------------------- |
| `heimdall_config:/config`| Persistent config, tiles, and themes   |

### Ports

| Port | Service   | Access               |
| ---- | --------- | -------------------- |
| 80   | Heimdall  | HTTP web UI          |
| 443  | Heimdall  | HTTPS web UI         |

## Updating

1. Bump `HEIMDALL_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. HTTPS

Heimdall ships its own nginx and exposes an HTTPS port (443) with a self-signed certificate. For a
managed reverse proxy with automatic certificates, put it behind one of the reverse-proxy stacks
([Caddy](../caddy/), [Traefik](../traefik/), [Nginx Proxy Manager](../nginx-proxy-manager/)) and
only expose the HTTP port.

### 2. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Heimdall starts automatically on
boot or failure.

### 3. Bind Mount for Config

Uncomment the bind mount in `docker-compose.yml` for easier management and backup of your
configuration:

```yaml
volumes:
  - /data/heimdall:/config
```

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 5. Authentication

To protect the dashboard with a username/password, generate an htpasswd file and uncomment the
`basic auth` lines in `/config/nginx/site-confs/default.conf`:

```bash
docker exec -it heimdall htpasswd -c /config/nginx/.htpasswd <username>
```

Then restart the container.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs heimdall
```

The healthcheck requests `http://localhost/`; a failure usually means Heimdall is still starting or
failed to bind.

### Port 80 or 443 already in use

Change `HEIMDALL_HTTP_PORT` / `HEIMDALL_HTTPS_PORT` in `.env` and re-run `docker compose up -d`.

### Permission errors on the config volume

Ensure `PUID`/`PGID` in `.env` match your host user (`id -u` / `id -g`) and that the named volume
is owned accordingly.

## Useful Commands

```bash
# View logs
docker compose logs -f heimdall

# Shell access
docker exec -it heimdall /bin/bash

# Container version
docker inspect -f '{{ index .Config.Labels "build_version" }}' heimdall
```

## Resources

- [Heimdall website](https://heimdall.site/)
- [linuxserver/heimdall documentation](https://docs.linuxserver.io/images/docker-heimdall/)
- [Official heimdall image on Docker Hub](https://hub.docker.com/r/linuxserver/heimdall)
