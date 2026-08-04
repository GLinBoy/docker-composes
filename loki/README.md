# Loki

[Grafana Loki](https://grafana.com/oss/loki/) is a horizontally-scalable, multi-tenant log
aggregation system inspired by Prometheus. It is designed to be very cost effective and easy to
operate — it does not index the contents of the logs, only a set of labels for each log stream.
This stack runs **Loki 3.x** in single-binary mode (`grafana/loki` image) with filesystem storage,
a named volume, and a custom network. It uses the image's built-in default config, which needs no
configuration file to get started.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port or timezone. The image is pinned to
`grafana/loki:3.7.4` by default — bump `LOKI_IMAGE` to update.

### 2. Start Loki

```bash
docker compose up -d
```

### 3. Verify Loki is Running

```bash
docker compose ps
```

The `loki` service should show as "healthy". The healthcheck uses Loki's built-in `-health`
command (which checks the `/ready` endpoint), because the image is distroless and ships without a
shell, `wget`, or `curl`.

### 4. Verify the HTTP API

```bash
curl -s http://localhost:3100/ready
# Expected: HTTP 200, body "ready"
```

You can also browse metrics at `http://localhost:3100/metrics` and the running config at
`http://localhost:3100/config`.

### 5. Send a Sample Log

```bash
# Replace <unix-epoch-ns> with a nanosecond timestamp, e.g. $(date +%s)000000000
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H 'Content-Type: application/json' \
  --data-raw '{"streams":[{"stream":{"job":"test"},"values":[["<unix-epoch-ns>","fizzbuzz"]]}]}'
```

### 6. Query It Back

```bash
curl -s 'http://localhost:3100/loki/api/v1/query_range?query={job="test"}' | jq
```

### 7. Stop Loki

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable     | Required | Description                                 |
| ------------ | -------- | ------------------------------------------- |
| `LOKI_IMAGE` | ❌       | Image tag (default `grafana/loki:3.7.4`)    |
| `LOKI_PORT`  | ❌       | Host port for the HTTP API (default `3100`) |
| `LOKI_TZ`    | ❌       | Container timezone (default `UTC`)          |

### Volumes

| Volume            | Purpose                                             |
| ----------------- | --------------------------------------------------- |
| `loki-data:/loki` | All index, chunk, and WAL data (filesystem backend) |

### Ports

| Port | Service       | Access               |
| ---- | ------------- | -------------------- |
| 3100 | Loki HTTP API | localhost by default |

## Production Considerations

### 1. Bind Mount for Data

Uncomment the bind mount in `docker-compose.yml` for easier backup control:

```yaml
volumes:
  - /data/loki:/loki
```

### 2. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 3. Custom Configuration

The image's default config (`loki-docker-config.yaml`) runs Loki in single-binary mode with
filesystem storage under `/loki`. To customize (retention, storage backend, etc.):

1. Create your own `loki-config.yaml` (start from the
   [Loki docs](https://grafana.com/docs/loki/latest/configure/examples/#1-local-configuration-example-yaml)).
2. Mount it and point Loki at it:

   ```yaml
   services:
     loki:
       volumes:
         - ./loki-config.yaml:/etc/loki/local-config.yaml:ro
   ```

   The default `CMD` already uses `-config.file=/etc/loki/local-config.yaml`, so a mount at that
   path is picked up automatically.

### 4. Retention

By default Loki keeps data indefinitely. To enable retention, add to a custom config:

```yaml
compactor:
  retention_enabled: true
  delete_request_store: filesystem
limits_config:
  retention_period: 30d
```

### 5. Sending Logs

To ship logs into Loki, point a client at the push endpoint `http://<host>:3100/loki/api/v1/push`:

- **Grafana** — add a "Loki" data source with URL `http://localhost:3100`
- **Promtail / Grafana Alloy** — configure a `loki.write` component targeting the push endpoint

## Troubleshooting

### Container is unhealthy

Check the logs:

```bash
docker compose logs loki
```

Common issues:

- Port `3100` already in use — change `LOKI_PORT` in `.env`
- Volume permissions — the image runs as UID `10001`; if you switched to a bind mount, ensure the
  host directory is writable by that UID (`sudo chown -R 10001:10001 /data/loki`)

### Reset the database

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f loki

# Query recent logs for a job (LogQL)
curl -s 'http://localhost:3100/loki/api/v1/query_range?query={job="test"}' | jq

# Tail logs for a job (WebSocket — use with a client like logcli)
docker compose exec loki /usr/bin/loki --version
```
