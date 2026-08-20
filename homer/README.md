# Homer

[Homer](https://github.com/bastienwirtz/homer) is a dead simple static homepage for your server to
keep all your services on hand, from a simple `yaml` configuration file. It runs the official
[b4bz/homer image](https://hub.docker.com/r/b4bz/homer) (Alpine-based, served by lighttpd) with a
named volume for your configuration and a custom network.

The container runs as uid/gid `1000` (`lighttpd`), which matches the ownership the image sets on
`/www/assets` — so the named volume is writable out of the box and `INIT_ASSETS` works without any
`user:` override.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port, subfolder, or timezone. The image is pinned to
`b4bz/homer:v26.4.2` by default — bump `HOMER_VERSION` to update.

### 2. Start Homer

```bash
docker compose up -d
```

On first start the container installs the example `config.yml` and default assets into the volume
(`INIT_ASSETS=1`).

### 3. Verify Homer is Running

```bash
docker compose ps
```

The `homer` service should show as "healthy".

### 4. Access the Web UI

Open `http://localhost:8080`. Edit `config.yml` inside the volume to configure your services,
groups, and themes:

```bash
docker exec -it homer sh -c "vi /www/assets/config.yml"
```

Then restart the container for changes to take effect (or just refresh — static files are served
from disk).

### 5. Stop Homer

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Homer start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable          | Required | Description                                                                 |
| ----------------- | -------- | --------------------------------------------------------------------------- |
| `HOMER_VERSION`   | ❌       | Image tag (default `b4bz/homer:v26.4.2`)                                    |
| `HOMER_PORT`      | ❌       | Host port for the web UI (default `8080`, mapped to container 8080)         |
| `INIT_ASSETS`     | ❌       | Install example config & assets on first run (default `1`, set `0` to skip) |
| `SUBFOLDER`       | ❌       | Serve under a subfolder, e.g. `/homer` (default `/`)                        |
| `HOMER_TZ`        | ❌       | Container timezone (default `UTC`)                                          |

### Volumes

| Volume                   | Purpose                                          |
| ------------------------ | ------------------------------------------------ |
| `homer_config:/www/assets` | Configuration (`config.yml`) and custom assets |

### Ports

| Port | Service | Access      |
| ---- | ------- | ----------- |
| 8080 | Homer   | Web UI      |

## Updating

1. Bump `HOMER_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Homer starts automatically on boot
or failure.

### 2. Bind Mount for Config

Uncomment the bind mount in `docker-compose.yml` for easier management and backup of your
configuration:

```yaml
volumes:
  - /data/homer:/www/assets
```

### 3. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 4. Reverse Proxy & Authentication

Put Homer behind one of the reverse-proxy stacks ([Caddy](../caddy/), [Traefik](../traefik/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) to get automatic TLS and add basic auth at the
proxy for extra protection.

### 5. Subfolder Hosting

If you want to reach Homer under a path like `https://my-domain/homer`, set `SUBFOLDER=/homer` in
`.env` and re-run `docker compose up -d`.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs homer
```

The healthcheck requests `http://localhost:8080/`; a failure usually means Homer is still starting
or the port is misconfigured.

### Config changes have no effect

Homer serves static files from the volume — changes to `config.yml` are picked up on page refresh.
If assets were never installed, check that the volume is writable and `INIT_ASSETS=1`.

### Port 8080 already in use

Change `HOMER_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f homer

# Shell access
docker exec -it homer /bin/sh

# Container version
docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.version" }}' homer
```

## Resources

- [Homer GitHub repository](https://github.com/bastienwirtz/homer)
- [Homer configuration documentation](https://github.com/bastienwirtz/homer/blob/master/docs/configuration.md)
- [b4bz/homer image on Docker Hub](https://hub.docker.com/r/b4bz/homer)
