# qBittorrent

[qBittorrent](https://www.qbittorrent.org/) is a free and open-source BitTorrent client, offering
a cross-platform feature set similar to µTorrent but without any ads. This stack runs the
`linuxserver/qbittorrent` image with persistent volumes for configuration and downloads.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum `PUID` / `PGID` to match your host user (find with `id -u` and
`id -g`). Optionally change the ports or timezone. The image is pinned to
`linuxserver/qbittorrent:5.2.3` by default — bump `QBITTORRENT_IMAGE` to update.

### 2. Start qBittorrent

```bash
docker compose up -d
```

### 3. Verify qBittorrent is Running

```bash
docker compose ps
```

The `qbittorrent` service should show as "healthy".

### 4. Access the Web UI

Open `http://localhost:8080` in your browser. On first login the default credentials are:

- **Username:** `admin`
- **Password:** `adminadmin`

> **SERVER:** change the default password in the Web UI before exposing it beyond localhost.

### 5. Stop qBittorrent

```bash
docker compose down
# Remove the named volumes too (deletes all data and downloads):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                 | Required | Description                                                        |
| ------------------------ | -------- | ------------------------------------------------------------------ |
| `QBITTORRENT_IMAGE`      | ❌       | Image tag (default `linuxserver/qbittorrent:5.2.3`)                |
| `PUID`                   | ❌       | Host user ID for file ownership (default `1000`)                   |
| `PGID`                   | ❌       | Host group ID for file ownership (default `1000`)                  |
| `TZ`                     | ❌       | Container timezone (default `UTC`)                                 |
| `WEBUI_PORT`             | ❌       | Container Web UI port (default `8080`)                             |
| `QBITTORRENT_WEBUI_PORT` | ❌       | Host Web UI port (default `8080`)                                  |
| `QBITTORRENT_BT_PORT`    | ❌       | Host BitTorrent port for TCP and UDP (default `6881`)              |

### Volumes

| Volume                   | Purpose                                  |
| ------------------------ | ---------------------------------------- |
| `qbittorrent_config`     | qBittorrent configuration and databases |
| `qbittorrent_downloads`  | Downloaded files                         |

### Ports

| Port | Purpose                                         |
| ---- | ----------------------------------------------- |
| 8080 | Web UI (TCP)                                    |
| 6881 | BitTorrent client (TCP and UDP)                 |

## Updating

1. Bump `QBITTORRENT_IMAGE` in `.env` to the next release (e.g. `5.2.4`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set `PUID` / `PGID` to the correct host user / group in `.env`
- [ ] Change the default Web UI password (`admin` / `adminadmin`) immediately
- [ ] Do not expose port 8080 to the public internet
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Uncomment the bind mounts for `qbittorrent_config` / `qbittorrent_downloads` for easier backup control

## Resources

- [qBittorrent documentation](https://github.com/qbittorrent/qBittorrent/wiki)
- [linuxserver/qbittorrent image on Docker Hub](https://hub.docker.com/r/linuxserver/qbittorrent)
