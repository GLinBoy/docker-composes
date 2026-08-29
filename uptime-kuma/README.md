# Uptime Kuma

[Uptime Kuma](https://uptime.kuma.pet/) is a self-hosted monitoring tool ("Uptime Robot" alternative):
it watches HTTP(s), TCP, Ping, DNS, Docker containers, push, and more — with fancy status pages and
90+ notification integrations. This stack runs the official
[louislam/uptime-kuma image](https://hub.docker.com/r/louislam/uptime-kuma) (Debian-based Node.js
app; v2 ships no Alpine variant) with a bind mount for its SQLite-backed data directory.

The healthcheck uses the `extra/healthcheck` binary that ships with the image — it GETs
`http://127.0.0.1:3001` and exits 0 on any HTTP response.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `louislam/uptime-kuma:2.5.0` by default. Change `UPTIME_KUMA_PORT` if `3001`
collides with another service.

### 2. Start Uptime Kuma

```bash
docker compose up -d
```

### 3. Verify Uptime Kuma is Running

```bash
docker compose ps
```

The `uptime-kuma` service should show as "healthy", and the Web UI should be up at
`http://localhost:3001/`. On first visit you create the admin account, then add your first monitor.

### 4. Add Monitors

Point a monitor at anything reachable from the container: a public URL, a sibling stack's published
host port (e.g. `http://<host-ip>:8080` for [Tomcat](../tomcat/)), or a container hostname on a
shared network (see below).

### 5. Stop the Stack

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Uptime Kuma start automatically, add `restart: unless-stopped` to the service.

## Monitoring Containers on Shared Networks

To monitor a sibling stack by container hostname instead of via host ports, attach Uptime Kuma to
that stack's network with a `compose.override.yml`:

```yaml
services:
  uptime-kuma:
    networks:
      - tomcat-network

networks:
  tomcat-network:
    external: true
    name: tomcat_tomcat-network
```

Then use e.g. `http://tomcat:8080` as the monitor URL. Sibling stacks in this repository
([Tomcat](../tomcat/), [Grafana](../grafana/), [Traefik](../traefik/), ...) all follow the same
network naming pattern (`<project>_<network-name>`).

## Data & Configuration

| Mount              | Purpose                                                 |
| ------------------ | ------------------------------------------------------- |
| `./data:/app/data` | SQLite DB (`kuma.db`), monitors, notifications, uploads |

> Uptime Kuma stores everything in **SQLite** — bind mounts on **NFS are not supported** (data
> corruption risk). Keep `./data` on a local filesystem.

| Host port (env)                | Container | Purpose          |
| ------------------------------ | --------- | ---------------- |
| `UPTIME_KUMA_PORT` (3001)      | 3001      | Web UI (TCP)     |

## Updating

1. Back up `./data` (see [Production Considerations](#production-considerations)).
2. Bump `UPTIME_KUMA_VERSION` in `.env` to the next release.
3. Pull and recreate the container — the DB migration runs automatically on first start:

```bash
## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Uptime Kuma starts automatically on
boot or failure — for a monitoring tool that usually is exactly what you want.

### 2. Backup the Data Directory

`./data` holds everything (monitors, history, notifications). For a consistent snapshot either stop
the stack first (`docker compose down`) or use the built-in **Settings → Backup** export, then keep
the export in your regular backup. The DB grows over time — check the size before backing up.

### 3. Reverse Proxy & TLS

Put Uptime Kuma behind one of the reverse-proxy stacks ([Traefik](../traefik/),
[Caddy](../caddy/), [Nginx Proxy Manager](../nginx-proxy-manager/)) for TLS. Uptime Kuma's
dashboard uses WebSockets — all three proxies handle that out of the box. When proxied, consider
unpublishing the port from `docker-compose.yml` and reaching Kuma only through the proxy.

### 4. Limit Exposure

The UI is protected by the admin account you create (2FA available). To bind it to localhost only,
publish `127.0.0.1:3001:3001` in `docker-compose.yml` and access via an SSH tunnel or the reverse
proxy.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. The Node.js process is
light for typical setups (dozens of monitors); heavy setups with very short intervals benefit from
more CPU.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs uptime-kuma
```

The bundled healthcheck needs an HTTP answer from the app; until the first-run setup completes the
server is already up, so failures usually mean the process crashed (check the log tail) or the
port inside the container was changed via `UPTIME_KUMA_PORT` env (the check honours it).

### Lost admin password

Reset it from inside the container:

```bash
docker exec -it uptime-kuma npm run reset-password
```

### Web UI doesn't load

- `UPTIME_KUMA_PORT` changed? Browse `http://localhost:$UPTIME_KUMA_PORT/`.
- Another service already binds the host port — free it or pick another port in `.env`.

### Data directory issues (corruption / NFS)

Kuma relies on SQLite locking — never place `./data` on NFS/network shares. If `kuma.db` got
corrupted, restore from backup; the official wiki documents repair options.

## Useful Commands

```bash
# View logs
docker compose logs -f uptime-kuma

# Shell access
docker exec -it uptime-kuma /bin/bash

# Reset the admin password (interactive)
docker exec -it uptime-kuma npm run reset-password

# Check the app's version
docker exec uptime-kuma node -e "console.log(require('./package.json').version)"
```

## Resources

- [Uptime Kuma website](https://uptime.kuma.pet/)
- [Uptime Kuma GitHub](https://github.com/louislam/uptime-kuma)
- [Uptime Kuma wiki (install & update guides)](https://github.com/louislam/uptime-kuma/wiki)
- [louislam/uptime-kuma on Docker Hub](https://hub.docker.com/r/louislam/uptime-kuma)