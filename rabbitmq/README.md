# RabbitMQ

[RabbitMQ](https://www.rabbitmq.com/) is the most widely deployed open-source message broker.
This stack runs the official `rabbitmq` image (Alpine variant with the management plugin
enabled) with a persistent data volume and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set `RABBITMQ_DEFAULT_USER` / `RABBITMQ_DEFAULT_PASS`. The image is pinned to
`rabbitmq:4.3.4-management-alpine` by default — bump `RABBITMQ_IMAGE` to update.

### 2. Start RabbitMQ

```bash
docker compose up -d
```

### 3. Verify RabbitMQ is Running

```bash
docker compose ps
```

The `rabbitmq` service should show as "healthy".

### 4. Access the Management UI

Open `http://localhost:15672` in your browser and log in with `RABBITMQ_DEFAULT_USER` and
`RABBITMQ_DEFAULT_PASS`.

> **SERVER:** the management UI is unencrypted by default — do not expose port 15672 to the
> public internet without TLS.

### 5. Stop RabbitMQ

```bash
docker compose down
# Remove the named volume too (deletes all queues, messages and data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                  | Required | Description                                                       |
| ------------------------- | -------- | ----------------------------------------------------------------- |
| `RABBITMQ_IMAGE`          | ❌       | Image tag (default `rabbitmq:4.3.4-management-alpine`)            |
| `RABBITMQ_DEFAULT_USER`   | ❌       | Default user created on first start (default `admin`)             |
| `RABBITMQ_DEFAULT_PASS`   | ✅       | Password for the default user                                     |
| `TZ`                      | ❌       | Container timezone (default `UTC`)                                |
| `RABBITMQ_AMQP_PORT`      | ❌       | Host AMQP port, clients connect here (default `5672`)             |
| `RABBITMQ_MANAGEMENT_PORT`| ❌       | Host management UI port (default `15672`)                         |
| `RABBITMQ_ERLANG_PORT`    | ❌       | Host Erlang distribution port, node/CLI (default `25672`)         |

### Volumes

| Volume          | Purpose                                              |
| --------------- | ---------------------------------------------------- |
| `rabbitmq_data` | Queues, messages and configuration (data directory) |

### Ports

| Port | Purpose                                 |
| ---- | --------------------------------------- |
| 5672 | AMQP protocol (client connections)      |
| 15672 | Management web UI                       |
| 25672 | Erlang distribution / node & CLI tools  |

## Connecting from Another Container

Services in the same Docker network can reach RabbitMQ using the service name `rabbitmq` on
port `5672`:

```yaml
services:
  myapp:
    networks:
      - rabbitmq-network
    environment:
      RABBITMQ_URL: amqp://admin:password@rabbitmq:5672
```

## Updating

1. Bump `RABBITMQ_IMAGE` in `.env` to the next release (e.g. `4.4.0-management-alpine`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `RABBITMQ_DEFAULT_PASS` in `.env`
- [ ] Do not expose ports 5672 / 15672 / 25672 to the public internet without TLS
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Uncomment the bind mount for `rabbitmq_data` for easier backup control

## Resources

- [RabbitMQ documentation](https://www.rabbitmq.com/docs)
- [Official rabbitmq image on Docker Hub](https://hub.docker.com/_/rabbitmq)
