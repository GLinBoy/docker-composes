# Apache Artemis

[Apache Artemis](https://artemis.apache.org/) is a multi-protocol message broker supporting AMQP 1.0,
MQTT, STOMP, and its native Core protocol. This stack runs the official `apache/artemis` image
(Alpine variant) with a named volume for the broker instance and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `ARTEMIS_PASSWORD` — generate a strong one with `openssl rand -hex 32`

### 2. Start Artemis

```bash
docker compose up -d
```

### 3. Verify Artemis is Running

```bash
docker compose ps
```

The `artemis` service should show as "healthy". The healthcheck spiders the Web Console on port 8161.

### 4. Open the Web Console

Browse to http://localhost:8161 and log in with the username and password you set in `.env`
(default `artemis`/`artemis`).

### 5. Stop Artemis

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                   | Required | Description                                 |
| -------------------------- | -------- | ------------------------------------------- |
| `ARTEMIS_IMAGE`            | ❌       | Image tag (default `apache/artemis:2.55.0-alpine`) |
| `ARTEMIS_PORT_CORE`        | ❌       | Core Protocol TCP port (default `61616`)    |
| `ARTEMIS_PORT_STOMP`       | ❌       | STOMP port (default `61613`)                |
| `ARTEMIS_PORT_MQTT`        | ❌       | MQTT port (default `1883`)                  |
| `ARTEMIS_PORT_AMQP`        | ❌       | AMQP port (default `5672`)                  |
| `ARTEMIS_PORT_HTTP`        | ❌       | Web Console HTTP port (default `8161`)      |
| `ARTEMIS_PORT_JMX`         | ❌       | JMX RMI Registry port (default `1099`)      |
| `ARTEMIS_TZ`               | ❌       | Container timezone (default `UTC`)          |
| `ARTEMIS_USER`             | ⚠️       | Admin username (default `artemis`)          |
| `ARTEMIS_PASSWORD`         | ⚠️       | Admin password (default `artemis`)          |
| `ARTEMIS_ANONYMOUS_LOGIN`  | ❌       | Allow anonymous logins (`true`/`false`, default `false`) |

### Volumes

| Volume                          | Purpose                                              |
| ------------------------------- | ---------------------------------------------------- |
| `artemis-instance:/var/lib/artemis-instance` | Broker instance config, data, and logs |

### Ports

| Port | Protocol     | Access               |
| ---- | ------------ | -------------------- |
| 61616 | Core (TCP)  | localhost by default |
| 61613 | STOMP        | localhost by default |
| 1883  | MQTT         | localhost by default |
| 5672  | AMQP         | localhost by default |
| 8161  | Web Console  | localhost by default |
| 1099  | JMX          | localhost by default |

## Connecting a Client

```bash
# Use the Artemis shell inside the container
docker compose exec artemis /var/lib/artemis-instance/bin/artemis shell --user artemis --password artemis

# Check server info
docker compose exec artemis /var/lib/artemis-instance/bin/artemis shell --user artemis --password artemis info
```

## Production Considerations

### Before Deploying to Production:

1. **Set Strong Credentials**

   In `.env`:

   ```bash
   ARTEMIS_USER=admin
   ARTEMIS_PASSWORD=<strong-password>
   ```

   Generate with `openssl rand -hex 32`. The default `artemis`/`artemis` is only for local testing.
   The credentials are applied when the broker instance is first created, so set them before the
   first start.

2. **Keep Anonymous Login Disabled**

   `ARTEMIS_ANONYMOUS_LOGIN` defaults to `false`. Keep it that way so clients must authenticate.

3. **Bind Mount for Data**

   Uncomment the bind mount in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/artemis:/var/lib/artemis-instance
   ```

4. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

5. **HTTPS**

   Put the Web Console behind a reverse proxy (see the
   [nginx-proxy-manager](../nginx-proxy-manager/), [Caddy](../caddy/), or [Traefik](../traefik/)
   stacks) to serve it over TLS.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs artemis
```

Artemis takes a few seconds to create the broker instance and start on first run — the
`start_period` of 30s covers this.

### Port already in use

Change the relevant `ARTEMIS_PORT_*` in `.env` and re-run `docker compose up -d`.

### Reset the broker

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f artemis

# Artemis shell (interactive)
docker compose exec artemis /var/lib/artemis-instance/bin/artemis shell --user artemis --password artemis

# Create a queue
docker compose exec artemis /var/lib/artemis-instance/bin/artemis shell --user artemis --password artemis queue create --name my-queue
```

## Resources

- [Apache Artemis documentation](https://artemis.apache.org/components/artemis/documentation/latest/)
- [Official apache/artemis image on Docker Hub](https://hub.docker.com/r/apache/artemis)
