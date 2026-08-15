# ActiveMQ

[Apache ActiveMQ Classic](https://activemq.apache.org/) is a popular open-source, multi-protocol
message broker. This stack runs the official `apache/activemq` image (ActiveMQ Classic 6.x) with
KahaDB message persistence on a named volume, a custom network, and support for OpenWire, STOMP,
MQTT, and AMQP 1.0 clients. The web console is available for management and monitoring.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the web console credentials, ports, or timezone. The image is
pinned to `apache/activemq:6.3.0` by default — bump `ACTIVEMQ_IMAGE` to update.

### 2. Start ActiveMQ

```bash
docker compose up -d
```

### 3. Verify ActiveMQ is Running

```bash
docker compose ps
```

The `activemq` service should show as "healthy". The healthcheck uses the image's built-in
`activemq status` command (checks the broker pidfile + process), because the image ships without
`curl`, `wget`, or `nc`.

### 4. Browse the Web Console

Open http://localhost:8161 in your browser and log in with the web console credentials
(default `admin` / `admin`). You can view queues, topics, and connected clients there.

### 5. Stop ActiveMQ

```bash
docker compose down
# Remove the named volume too (deletes all queued messages):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                 | Required | Description                                               |
| ------------------------ | -------- | --------------------------------------------------------- |
| `ACTIVEMQ_IMAGE`         | ❌       | Image tag (default `apache/activemq:6.3.0`)               |
| `ACTIVEMQ_WEB_USER`      | ❌       | Web console user (default `admin`)                        |
| `ACTIVEMQ_WEB_PASSWORD`  | ❌       | Web console password (default `admin` — set a strong one) |
| `ACTIVEMQ_PORT_OPENWIRE` | ❌       | Host port for OpenWire (default `61616`)                  |
| `ACTIVEMQ_PORT_STOMP`    | ❌       | Host port for STOMP (default `61613`)                     |
| `ACTIVEMQ_PORT_MQTT`     | ❌       | Host port for MQTT (default `1883`)                       |
| `ACTIVEMQ_PORT_AMQP`     | ❌       | Host port for AMQP 1.0 (default `5672`)                   |
| `ACTIVEMQ_PORT_WEB`      | ❌       | Host port for the web console (default `8161`)            |
| `ACTIVEMQ_PORT_JMX`      | ❌       | Host port for JMX RMI (default `1099` — inert, see below) |
| `ACTIVEMQ_TZ`            | ❌       | Container timezone (default `UTC`)                        |

### Volumes

| Volume                                    | Purpose                                                 |
| ----------------------------------------- | ------------------------------------------------------- |
| `activemq_data:/opt/apache-activemq/data` | KahaDB message store, journal, pidfile, and broker logs |

### Ports

| Port  | Protocol         | Access                          |
| ----- | ---------------- | ------------------------------- |
| 61616 | OpenWire (TCP)   | Java/JMS clients (local)        |
| 61613 | STOMP            | STOMP clients (local)           |
| 1883  | MQTT             | MQTT clients (local)            |
| 5672  | AMQP 1.0         | AMQP clients (local)            |
| 8161  | Web Console HTTP | http://localhost:8161           |
| 1099  | JMX RMI          | only active once JMX is enabled |

## Production Considerations

### 1. Strong Web Console Password

The web console defaults to `admin`/`admin`. Set a strong password in `.env` before exposing it
beyond localhost:

```bash
ACTIVEMQ_WEB_USER=admin
ACTIVEMQ_WEB_PASSWORD=$(openssl rand -hex 32)
```

### 2. Bind Mount for Data

Uncomment the bind mount in `docker-compose.yml` for easier backup control:

```yaml
volumes:
  - /data/activemq:/opt/apache-activemq/data
```

The container runs as UID `999` (`activemq`). If you switch to a bind mount, ensure the host
directory is writable by that UID:

```bash
sudo chown -R 999:999 /data/activemq
```

### 3. Resource Limits

ActiveMQ is a JVM process (the image defaults to `-Xmx1G`). Uncomment and tune the
`deploy.resources` block in `docker-compose.yml`.

### 4. Connection Authentication

By default broker connections are unauthenticated. The image can enable the
`simpleAuthenticationPlugin` when `ACTIVEMQ_CONNECTION_USER` / `ACTIVEMQ_CONNECTION_PASSWORD` are
set. Add them to the service environment in `docker-compose.yml`:

```yaml
environment:
  ACTIVEMQ_CONNECTION_USER: ${ACTIVEMQ_CONNECTION_USER:-}
  ACTIVEMQ_CONNECTION_PASSWORD: ${ACTIVEMQ_CONNECTION_PASSWORD:-}
```

Then define both variables in `.env` (generate with `openssl rand -hex 32`). Clients must then
authenticate before connecting.

### 5. JMX (Remote Monitoring)

Remote JMX is disabled by default (`createConnector="false"`), so the published `1099` port is
inert. To enable remote JMX, add to the service environment:

```yaml
environment:
  ACTIVEMQ_JMX_USER: ${ACTIVEMQ_JMX_USER:-}
  ACTIVEMQ_JMX_PASSWORD: ${ACTIVEMQ_JMX_PASSWORD:-}
```

Define both in `.env`. This sets `createConnector="true"` and configures
`conf/jmx.access` / `conf/jmx.password`.

### 6. Restart Policy

Containers stop when the host restarts (repo convention — no `restart:` policy is set). If you
want the broker to survive reboots, add to the service:

```yaml
restart: unless-stopped
```

## Troubleshooting

### Container is unhealthy

Check the logs:

```bash
docker compose logs activemq
```

Common issues:

- Port already in use — change the relevant `ACTIVEMQ_PORT_*` in `.env`
- Broker is still starting — ActiveMQ can take up to ~30s to be ready
- Volume permissions (bind mounts only) — ensure the host dir is owned by UID `999`

### Reset the broker

Remove the named volume and start fresh (deletes all queued messages):

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f activemq

# Check broker status from inside the container
docker compose exec activemq activemq status

# Browse queues/topics from the container CLI
docker compose exec activemq activemq query -QQueue

# Stop the stack
docker compose down
```
