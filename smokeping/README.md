# SmokePing

[SmokePing](https://oss.oetiker.ch/smokeping/) keeps track of network latency — it measures
latency to a set of targets over time and renders the results as graphs in a web interface. This
stack runs the `linuxserver/smokeping` image with persistent volumes for configuration and
monitoring data.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set `PUID` / `PGID` to match your host user (find with `id -u` and `id -g`).
The image is pinned to `linuxserver/smokeping:2.9.0` by default — bump `SMOKEPING_IMAGE` to
update.

### 2. Start SmokePing

```bash
docker compose up -d
```

### 3. Verify SmokePing is Running

```bash
docker compose ps
```

The `smokeping` service should show as "healthy".

### 4. Access the Web Interface

Open `http://localhost:19090` in your browser. The root URL redirects to the main dashboard at
`http://localhost:19090/smokeping/`.

### 5. Configure Targets

Edit the `Targets` file to define the hosts you want to monitor:

```bash
# The config volume is accessible from the container at /config
docker compose exec smokeping cat /config/Targets
```

Edit it (e.g. via `docker compose exec smokeping vi /config/Targets`), then reload the
configuration without restarting:

```bash
docker compose exec smokeping pkill -f -HUP '/usr/bin/perl /usr/s?bin/smokeping(_cgi)?'
```

### 6. Stop SmokePing

```bash
docker compose down
# Remove the named volumes too (deletes all config and data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable            | Required | Description                                                   |
| ------------------- | -------- | ------------------------------------------------------------- |
| `SMOKEPING_IMAGE`   | ❌       | Image tag (default `linuxserver/smokeping:2.9.0`)             |
| `PUID`              | ❌       | Host user ID for file ownership (default `1000`)              |
| `PGID`              | ❌       | Host group ID for file ownership (default `1000`)             |
| `TZ`                | ❌       | Container timezone (default `UTC`)                            |
| `SMOKEPING_PORT`    | ❌       | Host port for the web interface (default `19090`, maps to 80) |

### Volumes

| Volume             | Purpose                                          |
| ------------------ | ------------------------------------------------ |
| `smokeping_config` | Configuration (incl. the `Targets` file) at `/config` |
| `smokeping_data`   | Round-trip-time database and graphs at `/data`   |

### Ports

| Port  | Purpose        |
| ----- | -------------- |
| 19090 | Web interface  |

## Updating

1. Bump `SMOKEPING_IMAGE` in `.env` to the next release (e.g. `2.10.0`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set `PUID` / `PGID` to the correct host user / group in `.env`
- [ ] Set `SMOKEPING_PORT` to a non-default value or put the web interface behind a reverse proxy
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Uncomment the bind mounts for `smokeping_config` / `smokeping_data` for easier backup control

## Resources

- [SmokePing documentation](https://oss.oetiker.ch/smokeping/doc/)
- [linuxserver/smokeping image on Docker Hub](https://hub.docker.com/r/linuxserver/smokeping)
