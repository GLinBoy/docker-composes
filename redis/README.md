# Redis

[Redis](https://redis.io/) is an open-source, in-memory data structure store used as a database,
cache, message broker and streaming engine. This stack runs the official `redis` image (Alpine
variant) with a persistent data volume and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and optionally set `REDIS_PASSWORD`. The image is pinned to
`redis:8.10.0-alpine3.23` by default — bump `REDIS_IMAGE` to update.

### 2. Start Redis

```bash
docker compose up -d
```

### 3. Verify Redis is Running

```bash
docker compose ps
```

The `redis` service should show as "healthy".

### 4. Ping Redis

```bash
docker compose exec redis redis-cli ping
```

Expect `PONG`. If `REDIS_PASSWORD` is set, authenticate with:

```bash
docker compose exec redis redis-cli -a "$REDIS_PASSWORD" ping
```

### 5. Stop Redis

```bash
docker compose down
# Remove the named volume too (deletes all data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable         | Required | Description                                              |
| ---------------- | -------- | -------------------------------------------------------- |
| `REDIS_IMAGE`    | ❌       | Image tag (default `redis:8.10.0-alpine3.23`)            |
| `REDIS_PASSWORD` | ❌       | Optional AUTH password (empty = no auth, local dev only) |
| `TZ`             | ❌       | Container timezone (default `UTC`)                       |
| `REDIS_PORT`     | ❌       | Host port (default `6379`, maps to 6379)                 |

### Volumes

| Volume       | Purpose              |
| ------------ | -------------------- |
| `redis_data` | Redis persistence (RDB snapshots in `/data`) |

### Ports

| Port | Purpose     |
| ---- | ----------- |
| 6379 | Redis       |

## Connecting from Another Container

Services in the same Docker network can reach Redis using the service name `redis`:

```yaml
services:
  myapp:
    networks:
      - redis-network
    environment:
      REDIS_URL: redis://:password@redis:6379/0
```

## Updating

1. Bump `REDIS_IMAGE` in `.env` to the next release (e.g. `8.11.0-alpine3.23`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `REDIS_PASSWORD` in `.env`
- [ ] Do not expose port 6379 to the public internet
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Uncomment the bind mount for `redis_data` for easier backup control

## Resources

- [Redis documentation](https://redis.io/docs/)
- [Official redis image on Docker Hub](https://hub.docker.com/_/redis)
