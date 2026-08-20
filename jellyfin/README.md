# Jellyfin

[Jellyfin](https://jellyfin.org) is a free software media system that puts you in control of
managing and streaming your media — an open-source alternative to Emby and Plex with no premium
tiers. This stack runs the official [jellyfin/jellyfin
image](https://hub.docker.com/r/jellyfin/jellyfin) (Debian-based) with named volumes for config and
cache, a read-only bind mount for your media library, and a custom network.

The container runs as the uid/gid set by `PUID`/`PGID` (default `1000:1000`, never root) and the
image ships `curl` for the `/health` endpoint healthcheck.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` — most importantly set `MEDIA_DIR` to the folder holding your media and `PUID`/`PGID`
to your host user (`id -u` / `id -g`). The image is pinned to `jellyfin/jellyfin:10.11.11` by
default — bump `JELLYFIN_VERSION` to update.

### 2. Start Jellyfin

```bash
docker compose up -d
```

### 3. Verify Jellyfin is Running

```bash
docker compose ps
```

The `jellyfin` service should show as "healthy".

### 4. Access the Web UI

Open `http://localhost:8096` and follow the setup wizard — add your server, media library
(`/media`), and set up users.

### 5. Stop Jellyfin

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Jellyfin start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable                        | Required | Description                                                                            |
| ------------------------------- | -------- | -------------------------------------------------------------------------------------- |
| `JELLYFIN_VERSION`              | ❌       | Image tag (default `jellyfin/jellyfin:10.11.11`)                                       |
| `JELLYFIN_PORT`                 | ❌       | Host port for the web UI (default `8096`, mapped to container 8096)                    |
| `JELLYFIN_DLNA_PORT`            | ❌       | Host UDP port for client auto-discovery (default `7359`, mapped to container 7359)     |
| `PUID` / `PGID`                 | ❌       | User/group ID the container runs as (default `1000`/`1000`)                            |
| `MEDIA_DIR`                     | ❌       | Host path of your media library, mounted read-only at `/media`                          |
| `JELLYFIN_PUBLISHED_SERVER_URL` | ❌       | Public URL advertised for autodiscovery, e.g. `https://jellyfin.example.com` (empty)   |
| `JELLYFIN_TZ`                   | ❌       | Container timezone (default `UTC`)                                                     |

### Volumes

| Volume                      | Purpose                                      |
| --------------------------- | -------------------------------------------- |
| `jellyfin_config:/config`   | Configuration, metadata, and plugins         |
| `jellyfin_cache:/cache`     | Transcoding and image cache                  |
| `$MEDIA_DIR:/media` (ro)    | Host media library (bind mount, read-only)   |

> Add more bind mounts in `docker-compose.yml` for additional media libraries, e.g.
> `- /path/to/media2:/media2:ro`.

### Ports

| Port | Service | Access                 |
| ---- | ------- | ---------------------- |
| 8096 | Jellyfin| Web UI and API (TCP)  |
| 7359 | Jellyfin| Client auto-discovery (UDP) |

## Updating

1. Bump `JELLYFIN_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Jellyfin starts automatically on
boot or failure.

### 2. Bind Mounts for Config & Cache

Uncomment the bind mount driver options in `docker-compose.yml` for easier management and backup of
your metadata:

```yaml
volumes:
  jellyfin_config:
    driver_opts:
      type: none
      o: bind
      device: /data/jellyfin/config
  jellyfin_cache:
    driver_opts:
      type: none
      o: bind
      device: /data/jellyfin/cache
```

### 3. Media Permissions

Keep `/media` mounted read-only (`:ro`) — Jellyfin only needs to read your library. Ensure the
`PUID`/`PGID` user can read the media directory on the host.

### 4. Hardware Acceleration

To transcode with your GPU, uncomment the device in `docker-compose.yml`:

```yaml
devices:
  - /dev/dri:/dev/dri
```

Refer to the
[hardware acceleration docs](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/)
for vendor-specific setup (VA-API, QSV, NVENC, ...).

### 5. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. Transcoding is CPU- and
memory-hungry — give Jellyfin enough headroom.

### 6. Reverse Proxy

Put Jellyfin behind one of the reverse-proxy stacks ([Caddy](../caddy/), [Traefik](../traefik/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) for automatic TLS. Set
`JELLYFIN_PUBLISHED_SERVER_URL` so clients autodiscover the public URL.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs jellyfin
```

The healthcheck requests `http://localhost:8096/health`; first startup can take a while (database
migrations), so allow up to the 60s start period.

### Media library is empty

Double-check `MEDIA_DIR` points to the right host path and that the `PUID`/`PGID` user can read it.
Verify inside the container:

```bash
docker exec -it jellyfin ls /media
```

### Port 8096 or 7359 already in use

Change `JELLYFIN_PORT` / `JELLYFIN_DLNA_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f jellyfin

# Shell access
docker exec -it jellyfin /bin/sh

# Check the health endpoint
curl -sf http://localhost:8096/health

# Container version
docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.version" }}' jellyfin
```

## Resources

- [Jellyfin website](https://jellyfin.org)
- [Jellyfin container installation docs](https://jellyfin.org/docs/general/installation/container/)
- [Jellyfin hardware acceleration docs](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/)
- [jellyfin/jellyfin image on Docker Hub](https://hub.docker.com/r/jellyfin/jellyfin)