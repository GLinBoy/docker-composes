# Kong

[Kong](https://konghq.com/) is a cloud-native API gateway — route, secure, and observe your HTTP
traffic in front of your services. This stack runs Kong's official image backed by PostgreSQL,
where Kong persists all its configuration (services, routes, plugins, consumers).

A one-shot `kong-migration` job bootstraps Kong's schema on first start; `kong` only comes up after
it completes. Data lives in a named volume and survives restarts.

> **Note on Konga** — older Kong setups paired Kong with
> [Konga](https://hub.docker.com/r/pantsel/konga), a GUI that has been **unmaintained since 2020**.
> Its bundled database driver cannot authenticate or migrate against the modern PostgreSQL (13+)
> that Kong 3.x requires (it needs the `pg_constraint.consrc` column, removed in PostgreSQL 12).
> This stack therefore omits Konga — Kong is managed through its Admin API/Dev Portal, and tools
> like [Kong Manager](https://docs.konghq.com/gateway/) (Enterprise) or a declarative `kong.yml`
> cover GUI-style workflows.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Fill in `POSTGRES_PASSWORD`. Generate a strong value with `openssl rand -hex 32`. Kong is pinned to
`kong:3.9` in `.env` — bump `KONG_VERSION` to update.

### 2. Start Kong

```bash
docker compose up -d
```

On first start Postgres initializes, the one-shot `kong-migration` job bootstraps Kong's schema, and
finally `kong` starts. First boot takes around a minute.

### 3. Verify Kong is Running

```bash
docker compose ps
```

`kong-database` and `kong` should show as **healthy**. The `kong-migration` job has exited `0`
once the schema is ready.

### 4. Add Your First Route

Kong's Admin API is on `http://localhost:8001`. For example, proxy `example.com` through Kong:

```bash
curl -s -X POST http://localhost:8001/services \
  -d 'name=httpbin' -d 'url=http://httpbin.org'
curl -s -X POST http://localhost:8001/services/httpbin/routes \
  -d 'paths[]=/httpbin'
curl -s http://localhost:8000/httpbin/get
```

### 5. Stop Kong

```bash
docker compose down
# Remove all Kong data too:
docker compose down -v
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have the stack start automatically, add `restart: unless-stopped` to the services as noted
> with `# SERVER:` comments in the compose file.

## Configuration

All knobs live in `.env` — no compose file edits needed for everyday changes.

| Variable                | Default                 | Purpose                                     |
| ----------------------- | ----------------------- | ------------------------------------------- |
| `KONG_VERSION`          | `3.9.3`                 | Kong image tag                              |
| `POSTGRES_IMAGE`        | `postgres:16.15-alpine` | Postgres image tag                          |
| `POSTGRES_USER`         | `kong`                  | Postgres role used by Kong                  |
| `POSTGRES_PASSWORD`     | —                       | Postgres password (required)                |
| `POSTGRES_DB`           | `kong`                  | Kong's database                             |
| `POSTGRES_PORT`         | `5432`                  | Host port for Postgres management           |
| `KONG_ADMIN_PORT`       | `8001`                  | Host port for the Admin API                 |
| `KONG_PROXY_PORT`       | `8000`                  | Host port for routed traffic                |
| `KONG_PROXY_TLS_PORT`   | `8443`                  | Host port for TLS proxy                     |
| `KONG_TZ`               | `UTC`                   | Timezone                                    |

## Troubleshooting

### Kong never becomes healthy

Check that the migration job completed:

```bash
docker compose ps
docker compose logs kong-migration
```

If it exited non-zero, fix the cause and re-run it:

```bash
docker compose up -d kong-migration && docker compose up -d kong
```

### Reset everything (schema, routes, services)

```bash
docker compose down -v && docker compose up -d
```

`down -v` deletes the Postgres volume, so the schema is bootstrapped from scratch by
`kong-migration`.

### Port already in use

Change the relevant `*_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f kong

# Query the Admin API
curl -s http://localhost:8001/status
curl -s http://localhost:8001/services

# Declarative config (alternative to Admin API):
# kong config && docker compose exec kong sh -c \
#   'KONG_DATABASE=off kong config parse /path/to/kong.yml'
```

## Resources

- [Kong website](https://konghq.com/)
- [Kong docs](https://docs.konghq.com/)
- [Kong Admin API reference](https://developer.konghq.com/gateway/admin-api/)
- [kong image on Docker Hub](https://hub.docker.com/r/kong/kong)
- [Kong supported third-party dependencies](https://developer.konghq.com/gateway/third-party-support/)