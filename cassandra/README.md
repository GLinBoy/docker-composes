# Cassandra

[Cassandra](https://cassandra.apache.org/) is an open-source, distributed NoSQL database designed
to handle large amounts of data across many commodity servers. It provides high availability with
no single point of failure and is a masterless, peer-to-peer cluster where every node is equally
responsible for data.

This stack runs a small Cassandra cluster of **two nodes** — `cassandra-0` (the seed/master) and
`cassandra-1` (a slave) — connected via a dedicated Docker network. Cassandra is masterless, so
"master"/"slave" here only describes the bootstrap order: `cassandra-0` is the seed node the
others join first.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

By default no secrets are needed. Optionally change:

- `CASSANDRA_IMAGE` - the exact Cassandra image to run
- `CASSANDRA_PORT` - the host port for CQL (default `9042`)
- `CASSANDRA_SEEDS` / `CASSANDRA_CLUSTER_NAME` / `CASSANDRA_DC` / `CASSANDRA_RACK`

> Change `CASSANDRA_CLUSTER_NAME` BEFORE first start. It must be identical on every node.

### 2. Start the Cluster

```bash
docker compose up -d
```

### 3. Verify the Cluster is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Connect to Cassandra

```bash
docker compose exec cassandra-0 cqlsh
```

Or from your host using `cqlsh` against the mapped port:

```bash
cqlsh 127.0.0.1 9042
```

### 5. View Logs

```bash
docker compose logs -f cassandra-0
```

### 6. Stop the Cluster

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have the cluster start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable                  | Required | Description                                                      |
| ------------------------- | -------- | ---------------------------------------------------------------- |
| `CASSANDRA_IMAGE`         | ❌       | Exact Cassandra image (exact-pinned, never `latest`)             |
| `CASSANDRA_SEEDS`         | ❌       | Seed nodes a node joins through (default: both nodes)            |
| `CASSANDRA_CLUSTER_NAME`  | ❌       | Cluster name — must match on all nodes                           |
| `CASSANDRA_DC`            | ❌       | Datacenter name (default: `datacenter1`)                         |
| `CASSANDRA_RACK`          | ❌       | Rack name (default: `rack1`)                                     |
| `CASSANDRA_PORT`          | ❌       | Host port for CQL (default: `9042`)                              |

### Volumes

| Volume              | Purpose                                    |
| ------------------- | ------------------------------------------ |
| `cassandra_0_data`  | Data files for `cassandra-0` (bind mount)  |
| `cassandra_1_data`  | Data files for `cassandra-1` (bind mount)  |

### Ports

| Port | Purpose              |
| ---- | -------------------- |
| 9042 | CQL client port      |

## Scaling Up

The compose file ships with **two nodes** by default (`cassandra-0` master/seed and
`cassandra-1` slave) to keep resource usage low. Cassandra is a peer-to-peer cluster, so every
additional node is equal — you add "slave" nodes; the first node always remains the seed.

### Adding a Slave Node

To add a third node (`cassandra-2`):

1. Add a new service to `docker-compose.yml` copying `cassandra-1`:

```yaml
  cassandra-2:
    image: ${CASSANDRA_IMAGE:-cassandra:5.0.8}
    container_name: cassandra-2
    depends_on:
      cassandra-0:
        condition: service_healthy
    environment:
      - CASSANDRA_CLUSTER_NAME=${CASSANDRA_CLUSTER_NAME:-Cassandra Cluster}
      - CASSANDRA_SEEDS=${CASSANDRA_SEEDS:-cassandra-0,cassandra-1}
      - CASSANDRA_DC=${CASSANDRA_DC:-datacenter1}
      - CASSANDRA_RACK=${CASSANDRA_RACK:-rack1}
    volumes:
      - cassandra_2_data:/var/lib/cassandra
    networks:
      - cassandra-network
    healthcheck:
      test: ["CMD-SHELL", "[ $$(nodetool statusgossip) = running ]"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 90s
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
  cassandra_2_data:
    driver: local
    # SERVER: Use a bind mount for easier backup control:
    # driver_opts:
    #   type: none
    #   o: bind
    #   device: /data/cassandra/node2
```

3. In `.env`, include the new node in `CASSANDRA_SEEDS` on **all** nodes:

```bash
CASSANDRA_SEEDS=cassandra-0,cassandra-1,cassandra-2
```

4. Start the new node:

```bash
docker compose up -d cassandra-2
```

5. Verify it joined the cluster:

```bash
docker compose exec cassandra-0 nodetool status
```

You should see `UN` (Up/Normal) for every node. Repeat the same steps for each additional node.

### Adding a Second Datacenter

To run nodes across datacenters, give each node a distinct `CASSANDRA_DC` and ensure the seed
list spans at least one node of each datacenter, e.g.:

```yaml
# cassandra-2 in a second datacenter
environment:
  - CASSANDRA_DC=datacenter2
  - CASSANDRA_SEEDS=cassandra-0,cassandra-2
```

See the [multi-datacentre docs](https://cassandra.apache.org/doc/latest/cassandra/architecture/dynamo.html#multidatacentre) for placement and replication strategy details.

## Updating

1. Bump `CASSANDRA_IMAGE` in `.env` to the next release (e.g. `cassandra:5.0.9`).
2. Pull and recreate the cluster:

```bash
docker compose pull
docker compose up -d
```

3. Upgrading a live cluster is done node by node — stop, upgrade, and restart one node at a time,
   verifying each with `nodetool status` before moving on. See the
   [upgrade guide](https://cassandra.apache.org/doc/latest/cassandra/operating/upgrade/index.html).

## Server Checklist

Before deploying to a production server:

- [ ] Give the cluster a real `CASSANDRA_CLUSTER_NAME` before first start
- [ ] Set `CASSANDRA_DC` / `CASSANDRA_RACK` if you run multiple datacenters or racks
- [ ] Use a firewall / network policy to restrict CQL (9042) and internode (7000) access
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service (Cassandra is memory-hungry)
- [ ] Consider bind mounts for `cassandra_0_data` / `cassandra_1_data` for easier backup control
- [ ] Review the [backup and restore guide](https://cassandra.apache.org/doc/latest/cassandra/operating/backups/index.html)
- [ ] Size `num_tokens` and the replication factor for your expected data volume before loading data

## Useful Commands

```bash
# Node status (UN = Up/Normal)
docker compose exec cassandra-0 nodetool status

# Show cluster info
docker compose exec cassandra-0 nodetool info

# View the CQL shell
docker compose exec cassandra-0 cqlsh
```

## Resources

- [Cassandra Documentation](https://cassandra.apache.org/doc/latest/)
- [Cassandra Docker Image](https://hub.docker.com/_/cassandra)
- [nodetool Reference](https://cassandra.apache.org/doc/latest/cassandra/operating/tools/nodetool/nodetool.html)
