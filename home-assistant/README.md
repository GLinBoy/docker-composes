# Home Assistant

[Home Assistant](https://www.home-assistant.io/) is an open-source home automation platform that
tracks and controls all devices at home. This stack runs the official
`homeassistant/home-assistant` container image with a named volume for your configuration and host
network mode for LAN device discovery.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the timezone or image version. The image is pinned to
`homeassistant/home-assistant:2026.8.1` by default — bump `HOME_ASSISTANT_IMAGE` to update.

### 2. Start Home Assistant

```bash
docker compose up -d
```

### 3. Verify Home Assistant is Running

```bash
docker compose ps
```

The `homeassistant` service should show as "healthy".

### 4. Access Home Assistant

Home Assistant runs in **host network mode** and listens on port 8123:

```bash
open http://localhost:8123
```

Follow the onboarding wizard to create your owner account and start adding integrations.

### 5. Stop Home Assistant

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Home Assistant start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable                 | Required | Description                                                              |
| ------------------------ | -------- | ------------------------------------------------------------------------ |
| `HOME_ASSISTANT_IMAGE`   | ❌       | Image tag (default `homeassistant/home-assistant:2026.8.1`)              |
| `HOME_ASSISTANT_TZ`      | ❌       | Container timezone (default `UTC`)                                       |

### Volumes

| Volume                                | Purpose                                         |
| ------------------------------------- | ----------------------------------------------- |
| `home_assistant_config:/config`       | Configuration, databases, and add-ons           |
| `/etc/localtime:/etc/localtime:ro`    | Host timezone data (read-only)                  |
| `/run/dbus:/run/dbus:ro`              | D-Bus socket (read-only, used by Bluetooth)     |

### Ports

| Port | Service        | Access                     |
| ---- | -------------- | -------------------------- |
| 8123 | Home Assistant | host network mode, LAN-wide |

> With `network_mode: host` the container shares the host network — no `ports:` mapping is needed
> and Home Assistant is reachable on every host interface. To isolate it, remove `network_mode: host`
> and publish `8123:8123` instead (also update the `# ports:` block in `docker-compose.yml`).

## Updating

1. Bump `HOME_ASSISTANT_IMAGE` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Home Assistant starts automatically
on boot or failure.

### 2. Bind Mount for Config

Uncomment the bind mount in `docker-compose.yml` for easier management and backup of your
configuration:

```yaml
volumes:
  - /data/homeassistant:/config
```

### 3. Privileged Mode

The container runs `privileged: true` because most device integrations (Zigbee/Z-Wave, Bluetooth,
USB) require broad host device access. This grants full host access — if you only need a specific
device, drop `privileged` and map just that device:

```yaml
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
```

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 5. Reverse Proxy

To put Home Assistant behind a TLS-terminating reverse proxy, set `trusted_proxies` in
`configuration.yaml` and use one of the proxy stacks ([Caddy](../caddy/),
[Traefik](../traefik/), [Nginx Proxy Manager](../nginx-proxy-manager/)).

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs homeassistant
```

The healthcheck probes TCP port 8123; a failure usually means Home Assistant is still starting (the
first boot can take a couple of minutes) or failed to bind.

### No access to the frontend

On newer Linux distributions, allow TCP 8123 through the firewall:

```bash
sudo ufw allow 8123/tcp
```

### Zigbee/Z-Wave stick not detected

Ensure the container user has access to `/dev/tty*` and map the device explicitly as shown under
[Privileged Mode](#3-privileged-mode).

## Useful Commands

```bash
# View logs
docker compose logs -f homeassistant

# Restart (config changes require a restart)
docker compose restart
```

## Resources

- [Home Assistant documentation](https://www.home-assistant.io/docs/)
- [Install Home Assistant Container](https://www.home-assistant.io/installation/linux/#install-home-assistant-container)
- [Official home-assistant image on Docker Hub](https://hub.docker.com/r/homeassistant/home-assistant)
