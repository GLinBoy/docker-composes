# Grafana

[Grafana](https://grafana.com/) is an open-source analytics and interactive visualization web
application. It provides charts, graphs and alerts for your data when connected to supported data
sources (Prometheus, Loki, InfluxDB, Elasticsearch, MySQL, PostgreSQL and many more).

This stack runs the [official Grafana image](https://hub.docker.com/r/grafana/grafana) with a
persistent data volume and a dedicated Docker network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `ADMIN_PASSWORD` - a strong admin password. Generate with:
  ```bash
  openssl rand -hex 16
  ```

Optionally change:

- `GRAFANA_VERSION` - the exact Grafana version to run (defaults to `latest` when unset)
- `ADMIN_USER` - the admin username (default `admin`)
- `GRAFANA_PORT` - the host port for the web UI (default `3000`)
- `GRAFANA_ALLOW_SIGN_UP` - allow public sign-ups (default `false`)
- `GRAFANA_TZ` - the timezone (default `UTC`)

### 2. Start Grafana

```bash
docker compose up -d
```

### 3. Verify Grafana is Running

```bash
docker compose ps
```

The service should show as "healthy".

### 4. Verify the Health API

```bash
curl -s http://localhost:3000/api/health
# Expected: {"database":"ok"}
```

### 5. Open the Web UI

Open **http://localhost:3000** and log in with the `ADMIN_USER` / `ADMIN_PASSWORD` credentials.

### 6. View Logs

```bash
docker compose logs -f grafana
```

### 7. Stop Grafana

```bash
docker compose down
# Remove the data volume too (full reset):
docker compose down -v
```

> Containers stop when the host restarts (no restart policy is set, per repository convention). To
> have Grafana start automatically, uncomment `restart: unless-stopped` on the service.

## Configuration

### Environment Variables

| Variable               | Required | Description                                                          |
| ---------------------- | -------- | -------------------------------------------------------------------- |
| `ADMIN_PASSWORD`       | ✅       | Admin password (`openssl rand -hex 16`)                              |
| `GRAFANA_VERSION`      | ❌       | Exact Grafana version (defaults to `latest` when unset)              |
| `ADMIN_USER`           | ❌       | Admin username (default: `admin`)                                    |
| `GRAFANA_PORT`         | ❌       | Host port for the web UI (default: `3000`)                           |
| `GRAFANA_ALLOW_SIGN_UP`| ❌       | Allow public sign-ups (default: `false`)                             |
| `GRAFANA_TZ`           | ❌       | Timezone (default: `UTC`)                                            |

### Volumes

| Volume          | Purpose                                            |
| --------------- | -------------------------------------------------- |
| `grafana_data`  | Grafana database, plugins and provisioning (`/var/lib/grafana`) |

### Ports

| Port | Service       | Access              |
| ---- | ------------- | ------------------- |
| 3000 | Grafana web UI | localhost by default |

### Provisioning

Grafana supports provisioning dashboards and data sources via config files. To enable it,
uncomment the provisioning mounts in `docker-compose.yml` and add your config files:

- `grafana/provisioning/dashboards`
- `grafana/provisioning/datasources`

See the [provisioning docs](https://grafana.com/docs/grafana/latest/administration/provisioning/).

## Updating

1. Bump `GRAFANA_VERSION` in `.env` to the next release (e.g. `14.0.0`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `ADMIN_PASSWORD` in `.env` — never deploy with `admin/admin`
- [ ] Put Grafana behind a reverse proxy (Caddy/Nginx/Traefik) with HTTPS/TLS termination
- [ ] Add `restart: unless-stopped` to the service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Consider a bind mount for `grafana_data` for easier backup control
- [ ] Back up the Grafana data volume regularly

## Resources

- [Grafana](https://grafana.com/)
- [Grafana documentation](https://grafana.com/docs/grafana/latest/)
- [Grafana Docker image](https://hub.docker.com/r/grafana/grafana)
