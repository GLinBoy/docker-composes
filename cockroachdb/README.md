# CockroachDB

[CockroachDB](https://www.cockroachlabs.com/) is a cloud-native, distributed SQL database built
on a transactional and strongly-consistent key-value store. It is horizontally scalable,
survives disk, machine, rack, and even datacenter failures, and speaks PostgreSQL wire protocol.

This stack runs a small CockroachDB cluster of **two nodes** — `roach1` (the seed/master) and
`roach2` (a slave) — connected via a dedicated Docker network, plus a one-time `init` service
that initializes the cluster. CockroachDB nodes are peers, so "master"/"slave" here only
describes the bootstrap order: `roach1` is the seed the other nodes join first.

> **Insecure mode** — this stack runs with `--insecure` for local development. Do **not** use
> it for production without securing the cluster (see [Server Checklist](#server-checklist)).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

By default no secrets are needed. Optionally change:

- `COCKROACHDB_IMAGE` - the exact CockroachDB image to run
- `COCKROACHDB_JOIN` - the seed list used to bootstrap/join the cluster
- `COCKROACHDB_SQL_PORT` / `COCKROACHDB_HTTP_PORT` - roach1 host ports (defaults `26257` / `8080`)
- `COCKROACHDB_SQL_PORT_2` / `COCKROACHDB_HTTP_PORT_2` - roach2 host ports (defaults `26258` / `8081`)

### 2. Start the Cluster

```bash
docker compose up -d
```

### 3. Verify the Cluster is Running

```bash
docker compose ps
```

All services should show as "healthy". The `init` service initializes the cluster once and then
stays idle so it can report healthy.

### 4. Connect to the Cluster

```bash
docker compose exec roach1 ./cockroach sql --insecure --host=roach1:26257
```

Or from your host using any PostgreSQL-compatible client:

```bash
cockroach sql --insecure --url='postgresql://root@localhost:26257/defaultdb?sslmode=disable'
```

### 5. Open the DB Console

The DB Console for `roach1` is available at http://localhost:8080 and for `roach2` at
http://localhost:8081.

### 6. View Logs

```bash
docker compose logs -f roach1
```

### 7. Stop the Cluster

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have the cluster start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable                  | Required | Description                                                       |
| ------------------------- | -------- | ----------------------------------------------------------------- |
| `COCKROACHDB_IMAGE`       | ❌       | Exact CockroachDB image (exact-pinned, never `latest`)            |
| `COCKROACHDB_JOIN`        | ❌       | Seed list used to bootstrap/join the cluster (default: both nodes)|
| `COCKROACHDB_SQL_PORT`    | ❌       | roach1 host port for SQL (default: `26257`)                       |
| `COCKROACHDB_HTTP_PORT`   | ❌       | roach1 host port for DB Console (default: `8080`)                 |
| `COCKROACHDB_SQL_PORT_2`  | ❌       | roach2 host port for SQL (default: `26258`)                       |
| `COCKROACHDB_HTTP_PORT_2` | ❌       | roach2 host port for DB Console (default: `8081`)                 |

### Volumes

| Volume        | Purpose                                        |
| ------------- | ---------------------------------------------- |
| `roach1_data` | Data files for `roach1` (bind mount)           |
| `roach2_data` | Data files for `roach2` (bind mount)           |

### Ports

| Port | Purpose                     |
| ---- | --------------------------- |
| 26257 | CockroachDB SQL (roach1)   |
| 8080  | DB Console (roach1)        |
| 26258 | CockroachDB SQL (roach2)   |
| 8081  | DB Console (roach2)        |
| 26357 | Inter-node traffic (internal) |

## Scaling Up

The compose file ships with **two nodes** by default (`roach1` master/seed and `roach2` slave)
to keep resource usage low. CockroachDB is a peer-to-peer cluster, so every additional node is
equal — you add "slave" nodes; the first node always remains the seed.

### Adding a Slave Node

To add a third node (`roach3`):

1. Add a new service to `docker-compose.yml` copying `roach2`. Use distinct SQL/HTTP host
   ports (e.g. `26259` / `8082`) and its own volume:

```yaml
  roach3:
    image: ${COCKROACHDB_IMAGE:-cockroachdb/cockroach:v26.2.5}
    container_name: roach3
    hostname: roach3
    command:
      - start
      - --insecure
      - --advertise-addr=roach3:26357
      - --http-addr=roach3:8082
      - --listen-addr=roach3:26357
      - --sql-addr=roach3:26259
      - --join=${COCKROACHDB_JOIN:-roach1:26357,roach2:26357}
    volumes:
      - roach3_data:/cockroach/cockroach-data
    ports:
      - "${COCKROACHDB_SQL_PORT_3:-26259}:26259"
      - "${COCKROACHDB_HTTP_PORT_3:-8082}:8082"
    networks:
      - cockroachdb-network
    healthcheck:
      test: ["CMD-SHELL", "cockroach node status --insecure --host=localhost:26357 && exit 0 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
    # SERVER: Uncomment and tune resource limits before deploying to production
    # deploy:
    #   resources:
    #     limits:
    #       cpus: '2.0'
    #       memory: 4G
    #     reservations:
    #       cpus: '0.5'
    #       memory: 1G
```

2. Add a matching named volume at the bottom of `docker-compose.yml`:

```yaml
volumes:
  roach3_data:
    driver: local
    # SERVER: Use a bind mount for easier backup control:
    # driver_opts:
    #   type: none
    #   o: bind
    #   device: /data/cockroachdb/node3
```

3. In `.env`, include the new node in `COCKROACHDB_JOIN` on **all** nodes:

```bash
COCKROACHDB_JOIN=roach1:26357,roach2:26357,roach3:26357
```

4. Start the new node:

```bash
docker compose up -d roach3
```

5. Verify it joined the cluster:

```bash
docker compose exec roach1 ./cockroach node status --insecure
```

You should see an `live` entry for every node. Repeat the same steps for each additional node.

> Ranges are replicated across nodes according to the replication factor. With 2 nodes the
> default factor of 3 cannot be fully satisfied, so consider a third node before loading real
> data.

## Updating

1. Bump `COCKROACHDB_IMAGE` in `.env` to the next release (e.g. `cockroachdb/cockroach:v27.1.0`).
2. Pull and recreate the cluster:

```bash
docker compose pull
docker compose up -d
```

3. Upgrading a live cluster is done node by node — stop, upgrade, and restart one node at a time,
   verifying each with `node status` before moving on. See the
   [upgrade guide](https://www.cockroachlabs.com/docs/stable/upgrade-cockroach-version.html).

## Server Checklist

Before deploying to a production server:

- [ ] **Do not use `--insecure` in production** — configure a secure cluster with certificates
      instead of the flags used in this compose file
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Restrict access to the SQL (26257/26258/26259...) and DB Console (8080/8081/8082...) ports
      with a firewall / reverse proxy
- [ ] Consider bind mounts for `roach1_data` / `roach2_data` for easier backup control
- [ ] Review the [backup and restore guide](https://www.cockroachlabs.com/docs/stable/backup-and-restore-overview.html)
- [ ] Size the replication factor (`--max-offset`/zone configs) and node count for your
      availability requirements before loading data

## Useful Commands

```bash
# Node status (live = Up)
docker compose exec roach1 ./cockroach node status --insecure

# Show a node's details
docker compose exec roach1 ./cockroach node ls --insecure

# View the SQL shell
docker compose exec roach1 ./cockroach sql --insecure --host=roach1:26257
```

## Resources

- [CockroachDB Documentation](https://www.cockroachlabs.com/docs/stable/)
- [CockroachDB Docker Image](https://hub.docker.com/r/cockroachdb/cockroach)
- [Start a Local Cluster in Docker](https://www.cockroachlabs.com/docs/stable/start-a-local-cluster-in-docker-linux.html)
