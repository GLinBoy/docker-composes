# NATS

[NATS](https://nats.io/) is an open-source, high-performance cloud-native messaging system — a
lightweight message broker with at-most-once, at-least-once, and exactly-once (JetStream) delivery
semantics. This stack runs a 2-node NATS cluster (`nats-0` master, `nats-1` slave) with JetStream
persistence on per-node named volumes and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the ports or cluster name. The image is pinned to
`nats:2.14.4-alpine3.22` by default — bump `NATS_IMAGE` to update.

### 2. Start NATS

```bash
docker compose up -d
```

The `nats-0` master and `nats-1` slave start together so the JetStream cluster can form.

### 3. Verify NATS is Running

```bash
docker compose ps
```

Both services should show as "healthy". The healthcheck hits the HTTP monitoring `/healthz` endpoint
on each node.

### 4. Publish and Subscribe

NATS ships no CLI client in the image, so use the official `nats` CLI or any client library:

```bash
# Subscribe
nats sub test.topic --server nats://localhost:4222

# Publish
nats pub test.topic "Hello, NATS!" --server nats://localhost:4222
```

### 5. Check the Cluster

```bash
curl -s http://localhost:8222/routez | jq .routes | head
curl -s http://localhost:8222/connz | jq .num_connections
```

### 6. Stop NATS

```bash
docker compose down
# Remove the volumes too (deletes all persisted JetStream data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable               | Required | Description                                            |
| ---------------------- | -------- | ------------------------------------------------------ |
| `NATS_IMAGE`           | ❌       | Image tag (default `nats:2.14.4-alpine3.22`)           |
| `NATS_CLUSTER_NAME`    | ❌       | Cluster name shared by all nodes (default `NATS`)      |
| `NATS_PORT_CLIENT_0`   | ❌       | Master client port (default `4222`)                    |
| `NATS_PORT_MONITOR_0`  | ❌       | Master monitoring port (default `8222`)                |
| `NATS_PORT_CLIENT_1`   | ❌       | Slave client port (default `4223`)                     |
| `NATS_PORT_MONITOR_1`  | ❌       | Slave monitoring port (default `8223`)                 |

### Volumes

| Volume         | Purpose                     |
| -------------- | --------------------------- |
| `nats_0_data:/data` | JetStream store for `nats-0` |
| `nats_1_data:/data` | JetStream store for `nats-1` |

### Ports

| Host | Container | Service                  | Access                     |
| ---- | --------- | ------------------------ | -------------------------- |
| 4222 | 4222      | NATS client (master)     | localhost by default       |
| 8222 | 8222      | HTTP monitor (master)    | http://localhost:8222      |
| 4223 | 4222      | NATS client (slave)      | localhost by default       |
| 8223 | 8222      | HTTP monitor (slave)     | http://localhost:8223      |
| 6222 | 6222      | Cluster routes (internal) | container network only    |

## Production Considerations

### 1. Client Authentication

This stack runs with no client authentication (matching NATS' default). Before exposing the broker
beyond localhost, add a `--user` / `--pass` (or `--auth` token) to the `command` of each service in
`docker-compose.yml`, or provide a config file with an `authorization` block.

### 2. Bind Mount for Data

Uncomment the bind mount in `docker-compose.yml` for easier backup control:

```yaml
volumes:
  - /data/nats-0:/data
  - /data/nats-1:/data
```

### 3. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. NATS is lightweight, but
JetStream memory/disk usage grows with stream size.

### 4. Restart Policy

Containers stop when the host restarts (repo convention — no `restart:` policy is set). If you want
the cluster to survive reboots, add to each service:

```yaml
restart: unless-stopped
```

## Scaling Up

The default stack runs 2 nodes — one master (`nats-0`) and one slave (`nats-1`). To add a third
node `nats-2`:

1. Add a service block (and a data volume) for the new node, naming it `nats-2` and pointing its
   route at the master:

```yaml
services:
  nats-2:
    image: ${NATS_IMAGE:-nats:2.14.4-alpine3.22}
    container_name: nats-2
    depends_on:
      nats-0:
        condition: service_started
    command:
      - --cluster_name=${NATS_CLUSTER_NAME:-NATS}
      - --server_name=nats-2
      - --cluster=nats://0.0.0.0:6222
      - --routes=nats://nats-0:6222
      - --http_port=8222
      - --jetstream
      - --store_dir=/data
    ports:
      - "${NATS_PORT_CLIENT_2:-4224}:4222"
      - "${NATS_PORT_MONITOR_2:-8224}:8222"
    volumes:
      - nats_2_data:/data
    networks:
      - nats-network
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O- http://localhost:8222/healthz 2>/dev/null | grep -q ok || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
```

2. Add the new volume:

```yaml
volumes:
  nats_2_data:
    driver: local
```

3. Add the new ports to `.env`:

```bash
NATS_PORT_CLIENT_2=4224
NATS_PORT_MONITOR_2=8224
```

4. Restart:

```bash
docker compose up -d
```

Each node keeps its own data volume, and JetStream meta-leader election handles node membership
automatically. Note: for a resilient JetStream quorum, deploy an **odd** number of nodes (3, 5, …).

## Backups

The JetStream stores live in the named volumes. Back them up directly:

```bash
docker run --rm -v nats_nats_0_data:/data -v "$PWD":/backup alpine tar czf /backup/nats-0-$(date +%F).tar.gz -C /data .
docker run --rm -v nats_nats_1_data:/data -v "$PWD":/backup alpine tar czf /backup/nats-1-$(date +%F).tar.gz -C /data .
```

## Troubleshooting

### Container is unhealthy

Check the logs:

```bash
docker compose logs nats-0
```

Common issues:

- Port already in use — change the relevant `NATS_PORT_*` in `.env`
- The slave cannot reach the master — both must be on `nats-network` (they are by default)
- First start still forming the JetStream meta group — allow up to ~30s

### Reset the cluster

Remove the volumes and start fresh (deletes all persisted JetStream data):

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f nats-0

# Monitoring endpoints
curl -s http://localhost:8222/varz     # server stats
curl -s http://localhost:8222/connz    # connections
curl -s http://localhost:8222/routez   # cluster routes
curl -s http://localhost:8222/jsz      # JetStream stats
curl -s http://localhost:8222/healthz  # health

# Interactive shell
docker compose exec nats-0 sh

# Stop the stack
docker compose down
```
