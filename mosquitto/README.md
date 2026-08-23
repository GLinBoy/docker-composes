# Mosquitto

[Eclipse Mosquitto](https://mosquitto.org/) is an open-source MQTT message broker. It implements
MQTT 5.0, 3.1.1, and 3.1 and is lightweight enough to run on low-power single-board computers. This
stack runs the official `eclipse-mosquitto` image with MQTT over TCP and WebSockets, message
persistence on a named volume, and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the ports or timezone. The image is pinned to
`eclipse-mosquitto:2.1.2-alpine` by default — bump `MOSQUITTO_IMAGE` to update.

### 2. Start Mosquitto

```bash
docker compose up -d
```

### 3. Verify Mosquitto is Running

```bash
docker compose ps
```

The `mosquitto` service should show as "healthy". The healthcheck performs a real subscribe/publish
round-trip on the `mosquitto/health` topic and fails if the broker is down or the subscriber times
out.

### 4. Publish and Subscribe

```bash
# Terminal 1 — subscribe
mosquitto_sub -h localhost -p 1883 -t 'test/topic'

# Terminal 2 — publish
mosquitto_pub -h localhost -p 1883 -t 'test/topic' -m 'Hello, MQTT!'
```

(Install the `mosquitto-clients` package if `mosquitto_sub` / `mosquitto_pub` are not on your host.)

### 5. Stop Mosquitto

```bash
docker compose down
# Remove the named volume too (deletes all retained messages):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable               | Required | Description                                  |
| ---------------------- | -------- | -------------------------------------------- |
| `MOSQUITTO_IMAGE`      | ❌       | Image tag (default `eclipse-mosquitto:2.1.2-alpine`) |
| `MOSQUITTO_PORT_MQTT`  | ❌       | Host port for MQTT over TCP (default `1883`) |
| `MOSQUITTO_PORT_WS`    | ❌       | Host port for MQTT over WebSockets (default `9001`) |
| `MOSQUITTO_TZ`         | ❌       | Container timezone (default `UTC`)           |

### Volumes

| Volume                   | Purpose                                        |
| ------------------------ | ---------------------------------------------- |
| `mosquitto_data:/mosquitto/data` | Persistent message store (when `persistence true`) |

### Ports

| Port | Protocol               | Access                         |
| ---- | ---------------------- | ------------------------------ |
| 1883 | MQTT (TCP)             | MQTT clients (local)           |
| 9001 | MQTT over WebSockets   | Web/MQTT.js clients (local)    |

## Configuration File

The broker is configured by `config/mosquitto.conf`, mounted read-only into the container. It
defines the two listeners (1883 TCP, 9001 WebSockets), enables persistence, and logs to stdout.

## Production Considerations

### 1. Enable Authentication

Anonymous access is enabled by default. Before exposing the broker beyond localhost, disable it and
create a password file. On the host (or inside a container):

```bash
docker compose exec mosquitto sh
mosquitto_passwd -c /mosquitto/config/passwd <user>
exit
```

Then update `config/mosquitto.conf`:

```conf
allow_anonymous false
password_file /mosquitto/config/passwd
```

And update the healthcheck in `docker-compose.yml` so it authenticates:

```yaml
healthcheck:
  test: ["CMD-SHELL", "mosquitto_sub -h localhost -u <user> -P <pass> -t 'mosquitto/health' -C 1 -W 5 & sleep 1; mosquitto_pub -h localhost -u <user> -P <pass> -t 'mosquitto/health' -m ok; wait"]
```

### 2. Bind Mount for Data

Uncomment the bind mount in `docker-compose.yml` for easier backup control:

```yaml
volumes:
  - /data/mosquitto:/mosquitto/data
```

The container runs as UID `1883` (`mosquitto`). If you switch to a bind mount, ensure the host
directory is writable by that UID:

```bash
sudo chown -R 1883:1883 /data/mosquitto
```

### 3. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 4. Restart Policy

Containers stop when the host restarts (repo convention — no `restart:` policy is set). If you want
the broker to survive reboots, add to the service:

```yaml
restart: unless-stopped
```

## Troubleshooting

### Container is unhealthy

Check the logs:

```bash
docker compose logs mosquitto
```

Common issues:

- Port already in use — change the relevant `MOSQUITTO_PORT_*` in `.env`
- Broker is still starting — Mosquitto takes ~1s to be ready, but the first healthcheck may race it
- Volume permissions (bind mounts only) — ensure the host dir is owned by UID `1883`

### Reset the broker

Remove the named volume and start fresh (deletes all retained messages):

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f mosquitto

# Interactive shell inside the container
docker compose exec mosquitto sh

# Publish from inside the container
docker compose exec mosquitto mosquitto_pub -h localhost -t 'test/topic' -m 'Hello'

# Subscribe from inside the container
docker compose exec mosquitto mosquitto_sub -h localhost -t 'test/topic'

# Stop the stack
docker compose down
```
