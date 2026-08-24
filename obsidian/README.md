# Obsidian

[Obsidian](https://obsidian.md/) is a powerful note-taking and knowledge base app that lets
you create, link, and organize your notes, with hundreds of plugins and themes. This stack
runs the official [`linuxserver/obsidian` image](https://hub.docker.com/r/linuxserver/obsidian),
which streams the Obsidian desktop app to your browser over HTTP/HTTPS.

Obsidian runs inside the container, so your notes, settings, and plugins persist in named
volumes on the host.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `PUID` / `PGID` - match these to your host user/group (run `id your_user`)

Optionally change:

- `OBSIDIAN_HTTP_PORT` / `OBSIDIAN_HTTPS_PORT` - the host ports for the web UI (defaults `3000` / `3001`)
- `OBSIDIAN_USER` / `OBSIDIAN_PASSWORD` - optional HTTP Basic auth for the web UI
- `OBSIDIAN_VERSION` - the exact image tag to run (defaults to `latest` when unset)

### 2. Start Obsidian

```bash
docker compose up -d
```

### 3. Verify Obsidian is Running

```bash
docker compose ps
```

The `obsidian` service should show as "healthy". First start can take a minute while the
desktop environment initializes.

### 4. Access the Web UI

Open `https://localhost:3001` in your browser and accept the self-signed certificate.

> The image also serves the GUI over plain HTTP on port `3000`, but **HTTPS is required for
> full functionality** (some browser features such as WebCodecs need a secure context).

### 5. Stop Obsidian

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have Obsidian start automatically, add `restart: unless-stopped` to the
> service.

## Configuration

### Environment Variables

| Variable                 | Required | Description                                                     |
| ------------------------ | -------- | --------------------------------------------------------------- |
| `OBSIDIAN_VERSION`       | ❌       | Image tag (default `linuxserver/obsidian:latest` when unset)    |
| `PUID`                   | ✅       | User ID to run the container as (match your host user)          |
| `PGID`                   | ✅       | Group ID to run the container as (match your host group)        |
| `TZ`                     | ❌       | Timezone (default `Etc/UTC`)                                    |
| `OBSIDIAN_HTTP_PORT`     | ❌       | Host port for HTTP (default `3000`, container fixed to 3000)    |
| `OBSIDIAN_HTTPS_PORT`    | ❌       | Host port for HTTPS (default `3001`, container fixed to 3001)    |
| `OBSIDIAN_USER`          | ❌       | HTTP Basic auth username (empty = no auth)                      |
| `OBSIDIAN_PASSWORD`      | ❌       | HTTP Basic auth password (empty = no auth)                      |

### Volumes

| Volume            | Purpose                                          |
| ----------------- | ------------------------------------------------ |
| `obsidian_config` | Obsidian app config, plugins, and themes         |
| `obsidian_data`   | Your notes vaults                                |

### Ports

| Port | Purpose              |
| ---- | -------------------- |
| 3000 | Desktop GUI over HTTP |
| 3001 | Desktop GUI over HTTPS (default access) |

## Authentication

By default the container has **no authentication** — anyone who can reach the port can use
Obsidian, including a terminal with passwordless `sudo` access inside the container.

- For a trusted local network, set `OBSIDIAN_USER` and `OBSIDIAN_PASSWORD` in `.env` to
  enable HTTP Basic auth.
- For internet exposure, put Obsidian behind a reverse proxy (e.g.
  [Nginx Proxy Manager](../nginx-proxy-manager/), [Caddy](../caddy/), [Traefik](../traefik/))
  with its own authentication. Consider the [hardening options](https://github.com/linuxserver/docker-obsidian#advanced-configuration)
  from the upstream image too.

## Updating

1. Check the [linuxserver/obsidian tags](https://hub.docker.com/r/linuxserver/obsidian/tags)
   for the latest release.
2. Bump `OBSIDIAN_VERSION` in `.env` (e.g. `1.14.0`).
3. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

Your notes and settings persist in the named volumes, so nothing is lost.

## Server Checklist

Before deploying to a production server:

- [ ] Set `PUID` / `PGID` in `.env` to match your host user/group
- [ ] Add `restart: unless-stopped` to the service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block in `docker-compose.yml`
- [ ] Enable authentication (`OBSIDIAN_USER` / `OBSIDIAN_PASSWORD`) and/or put Obsidian behind a reverse proxy
- [ ] Note that `seccomp:unconfined` disables a Docker security layer — remove it if not needed
- [ ] Back up the `obsidian_config` and `obsidian_data` volumes (or use bind mounts)

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs obsidian
```

The healthcheck probes `https://localhost:3001/`; a failure usually means the desktop
environment is still starting or the port is wrong.

### Blurry text / colors look off

Enable **FullColor 4:4:4** encoding in the browser UI sidebar, or switch the encoder to
`jpeg` (see the [upstream readme](https://github.com/linuxserver/docker-obsidian)).

### GUI doesn't load on older hardware

If the container logs show GPU/wayland errors, set `PIXELFLUX_WAYLAND=false` in the
environment to fall back to X11.

## Useful Commands

```bash
# View logs
docker compose logs -f obsidian

# Shell access
docker exec -it obsidian /bin/bash
```

## Resources

- [Obsidian website](https://obsidian.md/)
- [linuxserver/docker-obsidian GitHub repository](https://github.com/linuxserver/docker-obsidian)
- [linuxserver/obsidian image on Docker Hub](https://hub.docker.com/r/linuxserver/obsidian)
