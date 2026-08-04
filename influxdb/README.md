# InfluxDB

[InfluxDB](https://www.influxdata.com/) is an open-source time series database optimized for
high-write-volume, time-stamped data such as metrics, events, and sensor data. This stack runs
**InfluxDB 1.x** (the `influxdb:1.12.4-alpine` image) with a single service, named volume, and a
custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `INFLUXDB_ADMIN_USER` / `INFLUXDB_ADMIN_PASSWORD` — generate the password with `openssl rand -hex 32`
- (Optional) `INFLUXDB_DB`, `INFLUXDB_USER`, `INFLUXDB_USER_PASSWORD` — database and limited user created on first start

### 2. Start InfluxDB

```bash
docker compose up -d
```

### 3. Verify InfluxDB is Running

```bash
docker compose ps
```

The `influxdb` service should show as "healthy".

### 4. Verify the HTTP API

```bash
curl -s http://localhost:8086/ping
# Expected: 204 No Content
```

### 5. Use the InfluxDB Client

```bash
# Inside the container (auth disabled)
docker compose exec influxdb influx -execute 'SHOW DATABASES'

# With auth enabled
docker compose exec influxdb influx -username admin -password '<password>' -execute 'SHOW DATABASES'
```

### 6. Stop InfluxDB

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                     | Required | Description                                             |
| ---------------------------- | -------- | ------------------------------------------------------- |
| `INFLUXDB_IMAGE`             | ❌       | Image tag (default `influxdb:1.12.4-alpine`)            |
| `INFLUXDB_PORT`              | ❌       | Host port for the HTTP API (default `8086`)             |
| `INFLUXDB_TZ`                | ❌       | Container timezone (default `UTC`)                      |
| `INFLUXDB_DB`                | ❌       | Database created on first start                         |
| `INFLUXDB_USER`              | ❌       | User granted access to `INFLUXDB_DB`                    |
| `INFLUXDB_USER_PASSWORD`     | ⚠️       | Password for `INFLUXDB_USER`                            |
| `INFLUXDB_ADMIN_USER`        | ⚠️       | Admin user with all privileges                          |
| `INFLUXDB_ADMIN_PASSWORD`    | ⚠️       | Password for the admin user                             |
| `INFLUXDB_HTTP_AUTH_ENABLED` | ❌       | Enable authentication (`true`/`false`, default `false`) |

### Volumes

| Volume                            | Purpose                              |
| --------------------------------- | ------------------------------------ |
| `influxdb-data:/var/lib/influxdb` | All database data, WAL, and metadata |

### Ports

| Port | Service           | Access               |
| ---- | ----------------- | -------------------- |
| 8086 | InfluxDB HTTP API | localhost by default |

InfluxDB 1.x ships without a web UI (that was Chronograf, now part of InfluxDB 2.x). Use the
`influx` CLI or any client library over the HTTP API on port `8086`.

## Writing and Querying Data

```bash
# Write a single point (line protocol)
curl -i -XPOST 'http://localhost:8086/write?db=influxdb' \
  --data-binary 'weather,location=us-midwest temperature=82 1465839830100400200'

# Query it back
curl -G 'http://localhost:8086/query' --data-urlencode 'db=influxdb' \
  --data-urlencode 'q=SELECT * FROM weather'
```

## Production Considerations

### Before Deploying to Production:

1. **Enable Authentication**

   In `.env`, set:

   ```bash
   INFLUXDB_HTTP_AUTH_ENABLED=true
   INFLUXDB_ADMIN_USER=admin
   INFLUXDB_ADMIN_PASSWORD=<strong-password>
   ```

   Generate the password with `openssl rand -hex 32`. Keep auth disabled only for trusted local use.

2. **Bind Mount for Data**

   Uncomment the bind mount in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/influxdb:/var/lib/influxdb
   ```

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

4. **Backup Configuration**

   InfluxDB 1.x backups use the RPC port `8088` (not exposed here by default). To back up:

   ```bash
   docker compose exec influxdb influxd backup -portable /tmp/backup
   docker compose cp influxdb:/tmp/backup ./backup
   ```

## Troubleshooting

### Container is unhealthy

Check the logs:

```bash
docker compose logs influxdb
```

Common issues:

- Port `8086` already in use — change `INFLUXDB_PORT` in `.env`
- Auth enabled but wrong credentials used in the healthcheck-adjusted client commands

### Reset the database

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f influxdb

# Open an interactive influx shell
docker compose exec influxdb influx

# Query a database
docker compose exec influxdb influx -database influxdb -execute 'SHOW MEASUREMENTS'
```
