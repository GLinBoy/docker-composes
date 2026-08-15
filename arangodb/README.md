# ArangoDB

[ArangoDB](https://www.arangodb.com/) is an open-source multi-model database that natively combines
key-value, document, and graph data models with a single query language (AQL). This stack runs the
official `arangodb` image (Alpine-based) with two named volumes and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `ARANGO_ROOT_PASSWORD` — generate a strong one with `openssl rand -hex 32`

### 2. Start ArangoDB

```bash
docker compose up -d
```

### 3. Verify ArangoDB is Running

```bash
docker compose ps
```

The `arangodb` service should show as "healthy". The healthcheck hits the auth-free
`/_admin/server/availability` endpoint.

### 4. Open the Web UI

Browse to http://localhost:8529 and log in with user `root` and the password you set in `.env`.

### 5. Stop ArangoDB

```bash
docker compose down
# Remove the named volumes too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable               | Required | Description                                   |
| ---------------------- | -------- | --------------------------------------------- |
| `ARANGO_IMAGE`         | ❌       | Image tag (default `arangodb:3.12.10`)        |
| `ARANGO_PORT`          | ❌       | Host port (default `8529`, maps to 8529)      |
| `ARANGO_TZ`            | ❌       | Container timezone (default `UTC`)            |
| `ARANGO_ROOT_PASSWORD` | ⚠️       | Password for the `root` user (default `changeme`) |

### Volumes

| Volume                                | Purpose                            |
| ------------------------------------- | ---------------------------------- |
| `arangodb_data:/var/lib/arangodb3`     | Database files                     |
| `arangodb_apps_data:/var/lib/arangodb3-apps` | Foxx apps / application data |

### Ports

| Port | Service           | Access               |
| ---- | ----------------- | -------------------- |
| 8529 | ArangoDB HTTP/Web | localhost by default |

## Basic AQL Usage

```bash
# Open an interactive shell inside the container
docker compose exec arangodb arangosh

# Or run a one-off query
docker compose exec arangodb arangosh --javascript.execute-string 'db._databases()'
```

## Production Considerations

### Before Deploying to Production:

1. **Set a Strong Root Password**

   In `.env`:

   ```bash
   ARANGO_ROOT_PASSWORD=<strong-password>
   ```

   Generate with `openssl rand -hex 32`. The default `changeme` is only meant for local testing.

2. **Bind Mounts for Data**

   Uncomment the bind mounts in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/arangodb:/var/lib/arangodb3
     - /data/arangodb-apps:/var/lib/arangodb3-apps
   ```

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

4. **HTTPS**

   ArangoDB can serve TLS itself or sit behind a reverse proxy (see the
   [nginx-proxy-manager](../nginx-proxy-manager/), [Caddy](../caddy/), or [Traefik](../traefik/)
   stacks). Follow the
   [TLS documentation](https://docs.arangodb.com/stable/secure/encryption/).

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs arangodb
```

ArangoDB takes a few seconds to initialise the databases on first start — the `start_period` of 30s
covers this.

### Reset the database

Remove the named volumes and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f arangodb

# Interactive shell
docker compose exec arangodb arangosh

# List databases
docker compose exec arangodb arangosh --javascript.execute-string 'db._databases()'
```

## Resources

- [ArangoDB documentation](https://docs.arangodb.com/)
- [Official arangodb image on Docker Hub](https://hub.docker.com/_/arangodb)
