# Prometheus

[Prometheus](https://prometheus.io/) is a systems and service monitoring system with a
multi-dimensional data model, a flexible query language (PromQL), and an HTTP pull model for time
series collection. This stack runs the official `prom/prometheus` image with a bind-mounted config,
a named data volume, and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `prom/prometheus:v3.13.2` by default — bump `PROMETHEUS_IMAGE` to update.

### 2. Add Your Scrape Targets

Edit `prometheus.yml` and add the jobs/targets you want to monitor. The default config scrapes
Prometheus itself:

```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
```

### 3. Start Prometheus

```bash
docker compose up -d
```

### 4. Verify Prometheus is Running

```bash
docker compose ps
```

The `prometheus` service should show as "healthy".

### 5. Open the Web UI

Open http://localhost:9090 and run your first query, e.g. `up` (returns `1` for a healthy target).

### 6. Stop Prometheus

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable            | Required | Description                                             |
| ------------------- | -------- | ------------------------------------------------------- |
| `PROMETHEUS_IMAGE`  | ❌       | Image tag (default `prom/prometheus:v3.13.2`)           |
| `PROMETHEUS_PORT`   | ❌       | Host port (default `9090`, maps to 9090)                |

### Files & Volumes

| Path                        | Purpose                         |
| --------------------------- | ------------------------------- |
| `./prometheus.yml`          | Prometheus configuration        |
| `prometheus_data:/prometheus` | Time series data (WAL, blocks) |

### Ports

| Port | Service            | Access                |
| ---- | ------------------ | --------------------- |
| 9090 | Web UI / API       | localhost by default  |

## Production Considerations

### Before Deploying to Production:

1. **Bind Mount for Data**

   Uncomment the bind mount in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/prometheus:/prometheus
   ```

2. **Backups**

   Use the Prometheus HTTP API for backups (read the [TSDB docs](https://prometheus.io/docs/prometheus/latest/backfilling/)
   and [snapshot endpoint](https://prometheus.io/docs/prometheus/latest/querying/api/#tsdb-admin-apis)).

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

4. **HTTPS / Auth**

   Prometheus has no built-in authentication. Put it behind a reverse proxy (see the
   [nginx-proxy-manager](../nginx-proxy-manager/), [Caddy](../caddy/), or [Traefik](../traefik/)
   stacks) with basic auth or an external auth layer.

5. **Alerts**

   To send alert notifications, add a `rule_files:` section and an
   [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) configuration.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs prometheus
```

The healthcheck runs `wget` against `/-/healthy` — an unhealthy status usually means Prometheus
failed to start, often due to a malformed `prometheus.yml`. Validate the config with:

```bash
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

### Port 9090 already in use

Change `PROMETHEUS_PORT` in `.env` and re-run `docker compose up -d`.

### Reset the data

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f prometheus

# Validate the config
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Back up the data volume
docker run --rm -v prometheus_prometheus_data:/prometheus -v "$PWD":/backup alpine tar czf /backup/prometheus_data.tar.gz -C /prometheus .
```

## Resources

- [Prometheus documentation](https://prometheus.io/docs/)
- [Official prom/prometheus image on Docker Hub](https://hub.docker.com/r/prom/prometheus)
- [Example prometheus.yml](https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus.yml)
