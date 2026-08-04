# Nextcloud All-in-One

[Nextcloud AIO](https://nextcloud.com/all-in-one/) is the official, easy-to-deploy Nextcloud
installation method. A single **master container** orchestrates the whole stack — Nextcloud,
PostgreSQL, Redis, the high-performance backend, and optional apps (Talk, Office, built-in backup,
ClamAV, ...) — and manages updates through a simple web interface.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set `NEXTCLOUD_AIO_VERSION` (already pinned to a stable release). Optionally set
`NEXTCLOUD_DATADIR` to a host directory **before the first start** to store your files outside a
Docker volume.

### 2. Start the master container

```bash
docker compose up -d
```

### 3. First-run setup

1. Open the AIO interface at `https://<server-ip>:8080` (accept the self-signed certificate).
2. Enter the domain that points to this server (or use the built-in free deSEC domain).
3. Click **Start containers** — AIO creates and starts all sibling containers automatically.

### 4. Verify

```bash
docker compose ps
```

The `nextcloud-aio-mastercontainer` should show as healthy. After the initial setup you can also
check the per-container status inside the AIO interface.

## Access

| Service              | URL                    | Notes                                        |
| -------------------- | ---------------------- | -------------------------------------------- |
| AIO interface        | `https://<ip>:8080`    | Self-signed certificate                      |
| AIO interface (cert) | `https://<domain>:8443`| Valid cert — needs ports 80 + 8443 open      |
| Nextcloud            | `https://<domain>`     | Served by the Apache container on port 443   |

## Configuration

### Environment Variables

| Variable                | Required | Description                                              |
| ----------------------- | -------- | -------------------------------------------------------- |
| `NEXTCLOUD_AIO_VERSION` | ✅       | Exact master container image tag to deploy               |
| `NEXTCLOUD_HTTP_PORT`   | ❌       | Host port for HTTP redirect (default `80`)               |
| `NEXTCLOUD_AIO_PORT`    | ❌       | Host port for AIO interface (default `8080`)             |
| `NEXTCLOUD_HTTPS_PORT`  | ❌       | Host port for AIO interface w/ valid cert (default `8443`) |
| `TZ`                    | ❌       | Container timezone (default `Etc/UTC`)                   |
| `APACHE_IP_BINDING`     | ❌       | Apache bind IP (default `0.0.0.0`)                       |
| `NEXTCLOUD_DATADIR`     | ⚠️       | Host dir for Nextcloud data — set **before** first start |
| `NEXTCLOUD_MOUNT`       | ❌       | Allow access to extra host directories                   |
| `NEXTCLOUD_UPLOAD_LIMIT`| ❌       | Public upload limit (default `16G`)                      |
| `NEXTCLOUD_MAX_TIME`    | ❌       | Max upload/execution time in seconds (default `3600`)    |
| `NEXTCLOUD_MEMORY_LIMIT`| ❌       | PHP memory limit per process (default `512M`)            |
| `AIO_LOG_LEVEL`         | ❌       | Log level: `debug`, `info`, `warn`, `error`              |

### Volumes

| Volume                              | Purpose                                              |
| ----------------------------------- | ---------------------------------------------------- |
| `nextcloud_aio_mastercontainer`     | AIO configuration — do not rename or remove (the built-in backup solution depends on it) |

> The master container also mounts `/var/run/docker.sock` (read-only) to orchestrate the sibling
> containers.

## Server Checklist

- [ ] Ports `80`, `8080`, `8443` are free on the host
- [ ] Ports `443/TCP` (and `443/UDP` for HTTP/3) open for the Apache container if exposing publicly
- [ ] Ports `3478/TCP` + `3478/UDP` open if you enable **Nextcloud Talk**
- [ ] Firewall/router forwards ports 80 + 8443 to the server for automatic certificates
- [ ] Docker is not a snap package (unsupported by AIO) — check `docker info | grep "Docker Root Dir"`

## Restart Policy

Per this repo's `AGENTS.md`, no restart policy is set — the stack stops when the host restarts.
Nextcloud AIO's official setup recommends `restart: always` on the master container so the whole
stack comes back up after a reboot. If you want that, add it to the service:

```yaml
services:
  nextcloud-aio-mastercontainer:
    restart: always
```

## Useful Commands

```bash
# Run occ commands (e.g. for troubleshooting or configuration)
docker exec --user www-data -it nextcloud-aio-nextcloud php occ your-command

# Trigger a backup from the CLI
docker exec --env DAILY_BACKUP=1 nextcloud-aio-mastercontainer /daily-backup.sh
```

## Reverse Proxy

If you place Nextcloud behind your own reverse proxy (Nginx, Traefik, Caddy, ...), follow the
[official reverse proxy documentation](https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md).
Typically you remove the `80`/`8443` port mappings and set `APACHE_IP_BINDING=127.0.0.1` plus a
custom `APACHE_PORT` for the Apache container.
