# Dozzle

[Dozzle](https://dozzle.dev/) is a small, lightweight application with a web-based interface to
monitor Docker container logs. It doesn't store log files — it streams them live from the Docker
engine, so you always see the most recent output.

This stack runs Dozzle in **standalone** mode (`docker compose up -d`). A Swarm-mode variant is
documented in the [Docker Swarm](#docker-swarm) section below.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Optionally change:

- `DOZZLE_PORT` - the host port for the web UI (default `8080`)
- `DOZZLE_VERSION` - the exact Dozzle version to run (defaults to `latest` when unset)
- `DOZZLE_TZ` - the timezone (default `UTC`)

### 2. Start Dozzle

```bash
docker compose up -d
```

### 3. Verify Dozzle is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Open the Web UI

Open http://localhost:8080. Dozzle lists all running containers; click any of them to stream its
logs in real time.

### 5. View Logs

```bash
docker compose logs -f dozzle
```

### 6. Stop Dozzle

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Dozzle start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable          | Required | Description                                                    |
| ----------------- | -------- | -------------------------------------------------------------- |
| `DOZZLE_VERSION`  | ❌       | Exact Dozzle version (defaults to `latest` when unset)         |
| `DOZZLE_PORT`     | ❌       | Host port for the web UI (default: `8080`)                     |
| `DOZZLE_TZ`       | ❌       | Timezone (default: `UTC`)                                      |

### Volumes

| Volume           | Purpose                                                            |
| ---------------- | ------------------------------------------------------------------ |
| `dozzle-data`    | Dozzle settings (notification settings, etc.)                      |
| `docker.sock`    | Host Docker socket mount — required for Dozzle to access logs      |

### Ports

| Port | Purpose        |
| ---- | -------------- |
| 8080 | Dozzle web UI  |

## Enabling Optional Features

Dozzle ships with several features disabled by default for security reasons. Uncomment the
corresponding line in the compose file to enable them:

| Feature | Env var                  | Note                                                                  |
| ------- | ------------------------ | --------------------------------------------------------------------- |
| Actions | `DOZZLE_ENABLE_ACTIONS`  | Lets you stop/start/restart containers from the UI                    |
| Shell   | `DOZZLE_ENABLE_SHELL`    | Lets you open a shell inside any container from the UI                |
| Auth    | `DOZZLE_AUTH_PROVIDER`   | Require login (`simple`) — also set `DOZZLE_AUTH_TTL` (e.g. `1h`)     |
| Filter  | `DOZZLE_FILTER`          | Only show containers matching a filter (e.g. `label=com.example.app`) |

## Updating

1. Bump `DOZZLE_VERSION` in `.env` to the next release (e.g. `v10.7.2`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Add `restart: unless-stopped` to the service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 8080
- [ ] **Secure access**: mounting `docker.sock` gives Dozzle root-equivalent access to the host.
  Enable authentication (`DOZZLE_AUTH_PROVIDER=simple`) or restrict access via a reverse proxy.
  See the [security considerations](https://dozzle.dev/guide/authentication#security-considerations)
  before exposing Dozzle beyond your private network
- [ ] Keep Actions (`DOZZLE_ENABLE_ACTIONS`) and Shell (`DOZZLE_ENABLE_SHELL`) disabled unless
  you explicitly need them
- [ ] Back up the `dozzle-data` volume (it only holds UI settings — no logs are stored)

## Docker Swarm

If you run a Docker Swarm cluster and want Dozzle on every node, use this variant with
`docker stack deploy -c docker-compose.yml dozzle`:

```yaml
services:
  dozzle:
    image: amir20/dozzle:latest
    environment:
      - DOZZLE_MODE=swarm
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - 8080:8080
    networks:
      - dozzle
    deploy:
      mode: global
networks:
  dozzle:
    driver: overlay
```

See the [Swarm mode guide](https://dozzle.dev/guide/swarm-mode) for details.
