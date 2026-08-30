# WUD (What's Up Docker)

[WUD](https://getwud.github.io/wud/) is a lightweight, open-source tool that continuously monitors
your running containers, discovers image updates across all major registries (Docker Hub, GHCR,
Quay, …), and notifies you — or triggers updates automatically. It runs the official
[getwud/wud image](https://hub.docker.com/r/getwud/wud) and needs access to the **Docker socket**
to watch containers.

The compose healthcheck probes the `/health` REST endpoint with `curl` (as recommended by the
official docs).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `getwud/wud:8.3.1` (the current `v8.x` stable release).

### 2. Start WUD

```bash
docker compose up -d
```

### 3. Verify WUD is Running

```bash
docker compose ps
```

The `wud` service should show as "healthy", and the dashboard is available at
`http://localhost:3000/`. Give it a few seconds to scan your running containers.

### 4. Configure Notifications (Optional)

Global settings live on the **WUD service** via `WUD_*` environment variables; per-container tuning
is done with `wud.*` **labels** on the monitored containers. Examples:

```yaml
# On the monitored container — only consider what you want and link releases:
labels:
  - "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
  - "wud.link.template=https://github.com/your/app/releases/tag/$${major}.$${minor}.$${patch}"
```

Add triggers (Telegram, Gotify, Slack, SMTP, …) or auto-update by appending the matching `WUD_*`
variables to the `wud` service — see the [Configuration Hub](https://getwud.github.io/wud/docs/configuration/).

### 5. Stop the Stack

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have WUD start automatically, add `restart: unless-stopped` to the service.

## Data & Configuration

| Mount                    | Container path        | Purpose                                        |
| ------------------------ | --------------------- | ---------------------------------------------- |
| `/var/run/docker.sock`   | `/var/run/docker.sock`| Docker socket — lets WUD watch containers      |
| `store_data`             | `/store`              | Persistent state (dismissed updates, history)  |

| Host port (env)    | Container | Purpose              |
| ------------------ | --------- | -------------------- |
| `WUD_PORT` (3000)  | 3000      | Web UI + REST API    |

### Environment Variables

| Variable          | Required | Description                                        |
| ----------------- | -------- | -------------------------------------------------- |
| `WUD_IMAGE`       | ❌       | Image tag (default `getwud/wud:8.3.1`)             |
| `WUD_PORT`        | ❌       | Host port (default `3000`, maps to 3000)           |
| `WUD_LOG_LEVEL`   | ❌       | Log verbosity (`debug`, `info`, `warn`, `error`)   |
| `TZ`              | ❌       | Container timezone (default `UTC`)                 |

Any other `WUD_*` setting (registries, triggers, auth, watchers) can be added in the compose
`environment:` block — see the [Configuration Hub](https://getwud.github.io/wud/docs/configuration/).

## Updating

1. Bump `WUD_IMAGE` in `.env` (check [releases](https://github.com/getwud/wud/releases)).
2. Pull and recreate — state survives in `store_data`:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. The Docker Socket Is Powerful

WUD needs `/var/run/docker.sock` (it cannot watch containers without it) — but that socket grants
root-equivalent control of the Docker daemon. Only run trusted images as the sole producer of your
containers, keep WUD on a dedicated host/network if possible, and protect the web UI.

### 2. Protect the Web UI

The dashboard and REST API are unauthenticated by default. Enable **Basic Auth** (`WUD_AUTH_BASIC_*`)
or OIDC before exposing WUD to anything but localhost, and terminate TLS with a reverse proxy
([Traefik](../traefik/), [Caddy](../caddy/), [Nginx Proxy Manager](../nginx-proxy-manager/)).

### 3. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` if you want WUD back automatically
after a reboot.

### 4. Backups

`store_data` holds only monitoring state — small and easy to back up. Your actual services are not
touched by WUD unless you configure auto-update triggers (those recreate containers using the same
image they already run — always review update labels first).

### 5. Resource Limits

Uncomment and tune the `deploy.resources` block. WUD is lightweight — 256M is a comfortable limit.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs wud
```

The healthcheck needs a successful response on `http://localhost:3000/health`. If WUD cannot reach
the Docker daemon (socket permission issues), it fails early — make sure the host is running
Docker and the socket path is valid.

### No containers are showing in the UI

WUD only discovers **running** containers matching its watcher configuration. If you use
compose projects, ensure `WUD_WATCH_*` covers them (defaults watch the local Docker daemon). Also
check the log level is at least `info`.

### Registries time out / private images unknown

Authenticate the registry with `WUD_REGISTRY_*` env vars (e.g. Docker Hub, GHCR) — see
[Registries](https://getwud.github.io/wud/docs/configuration/registries/).

### Port already in use

Change `WUD_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f wud

# Shell access
docker compose exec wud /bin/sh

# Verify the health endpoint directly
curl -s http://localhost:3000/health
```

## Resources

- [WUD website & docs](https://getwud.github.io/wud/)
- [Configuration Hub](https://getwud.github.io/wud/docs/configuration/)
- [getwud/wud on Docker Hub](https://hub.docker.com/r/getwud/wud)
- [getwud/wud on GitHub](https://github.com/getwud/wud)