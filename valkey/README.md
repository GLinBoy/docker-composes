# Valkey

[Valkey](https://valkey.io/) is the open-source, Redis-compatible in-memory data store (a Linux
Foundation project forked from Redis 7.4) used as a database, cache and message broker. This stack
runs the official `valkey/valkey` image (Alpine variant) with RDB persistence, a named data volume
and a custom network — with the container running under dropped capabilities (`cap_drop: ALL`).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and optionally set `VALKEY_PASSWORD`. The image is pinned to
`valkey/valkey:9.1.1-alpine3.24` by default — bump `VALKEY_IMAGE` to update.

### 2. Start Valkey

```bash
docker compose up -d
```

### 3. Verify Valkey is Running

```bash
docker compose ps
```

The `valkey` service should show as "healthy".

### 4. Ping Valkey

```bash
docker compose exec valkey valkey-cli ping
```

Expect `PONG`. If `VALKEY_PASSWORD` is set, authenticate with:

```bash
docker compose exec valkey valkey-cli --pass "$VALKEY_PASSWORD" ping
```

### 5. Stop Valkey

```bash
docker compose down
# Remove the named volume too (deletes all data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable          | Required | Description                                                   |
| ----------------- | -------- | ------------------------------------------------------------- |
| `VALKEY_IMAGE`    | ❌       | Image tag (default `valkey/valkey:9.1.1-alpine3.24`)          |
| `VALKEY_PASSWORD` | ❌       | Optional AUTH password (empty = no auth, local dev only)      |
| `TZ`              | ❌       | Container timezone (default `UTC`)                            |
| `VALKEY_PORT`     | ❌       | Host port (default `6379`, maps to 6379)                      |

Setting `VALKEY_PASSWORD` rewrites the start command to include `--requirepass` and makes the
healthcheck authenticate — no compose edits needed.

### Volumes

| Volume       | Purpose                                       |
| ------------ | --------------------------------------------- |
| `valkey_data` | Valkey persistence (RDB snapshots in `/data`) |

Persistence is RDB-only via `--save 30 1` (snapshot after 30 s if ≥ 1 key changed). For
append-only durability add `--appendonly yes` to the `command` in `docker-compose.yml`.

### Ports

| Port | Purpose |
| ---- | ------- |
| 6379 | Valkey  |

## Connecting from Another Container

Services in the same Docker network can reach Valkey using the service name `valkey`:

```yaml
services:
  myapp:
    networks:
      - valkey-network
    environment:
      VALKEY_URL: valkey://:password@valkey:6379/0
```

## Updating

1. Bump `VALKEY_IMAGE` in `.env` to the next release (e.g. `9.1.2-alpine3.24`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `VALKEY_PASSWORD` in `.env`
- [ ] Do not expose port 6379 to the public internet
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Uncomment the bind mount for `valkey_data` for easier backup control
- [ ] Consider `--appendonly yes` if you need durable writes between snapshots

## Resources

- [Valkey website](https://valkey.io/)
- [Valkey documentation](https://valkey.io/docs/)
- [Official valkey image on Docker Hub](https://hub.docker.com/r/valkey/valkey)