# CouchDB

[CouchDB](https://couchdb.apache.org/) is a document-oriented NoSQL database with a JSON-based
storage format, JavaScript as its query language, and an HTTP API. It supports offline-first
apps through peer-to-peer replication and can be clustered for horizontal scaling and high
availability.

This stack runs a small CouchDB cluster of **two nodes** — `couchdb-0` (the seed/master) and
`couchdb-1` (a slave) — connected via a dedicated Docker network. CouchDB nodes are peers, so
"master"/"slave" here only describes the bootstrap order: `couchdb-0` is the first node the
others join.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `COUCHDB_PASSWORD` - admin password (generate with `openssl rand -hex 24`)
- `COUCHDB_SECRET` - cluster shared secret (generate with `openssl rand -hex 32`)
- `COUCHDB_COOKIE` - Erlang distribution cookie (generate with `openssl rand -hex 32`)

> `COUCHDB_SECRET` and `COUCHDB_COOKIE` MUST be identical on every node in the cluster, and
> they must be set BEFORE first start. Change them only while the nodes are stopped.

Optionally change:

- `COUCHDB_IMAGE` - the exact CouchDB image to run
- `COUCHDB_PORT_0` / `COUCHDB_PORT_1` - host ports for the HTTP API (defaults `5984` / `5985`)

### 2. Start the Cluster

```bash
docker compose up -d
```

### 3. Verify the Cluster is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Connect to CouchDB

Open http://localhost:5984 and log in with `COUCHDB_USER` / `COUCHDB_PASSWORD` (Fauxton, the
built-in admin UI). Or use the API:

```bash
curl -u admin:yourpassword http://localhost:5984/
```

### 5. View Logs

```bash
docker compose logs -f couchdb-0
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

| Variable            | Required | Description                                                            |
| ------------------- | -------- | ---------------------------------------------------------------------- |
| `COUCHDB_USER`      | ✅       | Admin username (default: `admin`)                                      |
| `COUCHDB_PASSWORD`  | ✅       | Admin password                                                         |
| `COUCHDB_SECRET`    | ✅       | Cluster shared secret — identical on all nodes                         |
| `COUCHDB_COOKIE`    | ✅       | Erlang distribution cookie — identical on all nodes                    |
| `COUCHDB_IMAGE`     | ❌       | Exact CouchDB image (exact-pinned, never `latest`)                     |
| `COUCHDB_PORT_0`    | ❌       | Host port for couchdb-0 HTTP API (default: `5984`)                     |
| `COUCHDB_PORT_1`    | ❌       | Host port for couchdb-1 HTTP API (default: `5985`)                     |

### Volumes

| Volume            | Purpose                                     |
| ----------------- | ------------------------------------------- |
| `couchdb_0_data`  | Database files for `couchdb-0`              |
| `couchdb_0_cfg`   | Runtime config (`local.d`) for `couchdb-0`  |
| `couchdb_1_data`  | Database files for `couchdb-1`              |
| `couchdb_1_cfg`   | Runtime config (`local.d`) for `couchdb-1`  |

### Ports

| Port | Purpose                |
| ---- | ---------------------- |
| 5984 | CouchDB HTTP API       |
| 5985 | CouchDB HTTP API (node 2) |

## Setting Up the Cluster

Starting the containers alone does **not** join the nodes into a cluster — CouchDB must be
initialized via the [Cluster Setup API](https://docs.couchdb.org/en/stable/setup/cluster.html)
or Fauxton once the nodes are up.

The simplest way is the Fauxton Setup wizard:

1. Open http://localhost:5984/_utils#/setup on `couchdb-0`.
2. Leave "Single node" unchecked, set `couchdb-0` for the admin account (same as `.env`), add
   the remote node `couchdb-1`, and click "Configure Cluster".
3. Fauxton creates the `_users`, `_replicator`, and `_global_changes` system databases for you.

Alternatively, drive it from the API (run from any node):

```bash
# Enable clustering on couchdb-1
curl -s -X POST -H "Content-Type: application/json" \
  -u admin:yourpassword http://couchdb-0:5984/_cluster_setup \
  -d '{"action":"enable_cluster","bind_address":"0.0.0.0","username":"admin","password":"yourpassword","node_count":"2","remote_node":"couchdb-1","remote_current_user":"admin","remote_current_password":"yourpassword"}'

# Add couchdb-1 to the cluster
curl -s -X POST -H "Content-Type: application/json" \
  -u admin:yourpassword http://couchdb-0:5984/_cluster_setup \
  -d '{"action":"add_node","host":"couchdb-1","port":5984,"username":"admin","password":"yourpassword"}'

# Finish setup and create system databases
curl -s -X POST -H "Content-Type: application/json" \
  -u admin:yourpassword http://couchdb-0:5984/_cluster_setup \
  -d '{"action":"finish_cluster"}'
```

Verify the cluster:

```bash
curl -u admin:yourpassword http://localhost:5984/_membership
```

You should see both `couchdb@couchdb-0` and `couchdb@couchdb-1` in `all_nodes` / `cluster_nodes`.

## Scaling Up

The compose file ships with **two nodes** by default (`couchdb-0` master/seed and `couchdb-1`
slave) to keep resource usage low. CouchDB is a peer-to-peer cluster, so every additional node
is equal — you add "slave" nodes; the first node always remains the seed.

### Adding a Slave Node

To add a third node (`couchdb-2`):

1. Add a new service to `docker-compose.yml` copying `couchdb-1`, with a new host port and its
   own volumes:

```yaml
  couchdb-2:
    image: ${COUCHDB_IMAGE:-couchdb:3.5.2.1}
    container_name: couchdb-2
    depends_on:
      couchdb-0:
        condition: service_healthy
    environment:
      - COUCHDB_USER=${COUCHDB_USER}
      - COUCHDB_PASSWORD=${COUCHDB_PASSWORD}
      - COUCHDB_SECRET=${COUCHDB_SECRET}
      - NODENAME=couchdb-2
      - COUCHDB_ERLANG_COOKIE=${COUCHDB_COOKIE}
    volumes:
      - couchdb_2_data:/opt/couchdb/data
      - couchdb_2_cfg:/opt/couchdb/etc/local.d
    ports:
      - "${COUCHDB_PORT_2:-5986}:5984"
    networks:
      - couchdb-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5984/_up"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    # SERVER: Uncomment and tune resource limits before deploying to production
    # deploy:
    #   resources:
    #     limits:
    #       cpus: '1.0'
    #       memory: 1G
    #     reservations:
    #       cpus: '0.25'
    #       memory: 256M
```

2. Add matching named volumes at the bottom of `docker-compose.yml`:

```yaml
volumes:
  couchdb_2_data:
    driver: local
    # SERVER: Use a bind mount for easier backup control:
    # driver_opts:
    #   type: none
    #   o: bind
    #   device: /data/couchdb/node2/data
  couchdb_2_cfg:
    driver: local
    # SERVER: Use a bind mount for easier backup control:
    # driver_opts:
    #   type: none
    #   o: bind
    #   device: /data/couchdb/node2/cfg
```

3. Add `COUCHDB_PORT_2=5986` to `.env`.
4. Start the new node:

```bash
docker compose up -d couchdb-2
```

5. Join it to the cluster (same secret/cookie already configured via `.env`):

```bash
curl -s -X POST -H "Content-Type: application/json" \
  -u admin:yourpassword http://couchdb-0:5984/_cluster_setup \
  -d '{"action":"add_node","host":"couchdb-2","port":5984,"username":"admin","password":"yourpassword"}'
```

6. Verify it joined:

```bash
curl -u admin:yourpassword http://localhost:5984/_membership
```

## Updating

1. Bump `COUCHDB_IMAGE` in `.env` to the next release (e.g. `couchdb:3.6.0`).
2. Pull and recreate the cluster:

```bash
docker compose pull
docker compose up -d
```

3. CouchDB runs a data upgrade on first start — allow it to finish before using the cluster.
   Upgrade one node at a time and verify each with `_membership` before moving on.

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `COUCHDB_PASSWORD`, `COUCHDB_SECRET`, and `COUCHDB_COOKIE` in `.env`
- [ ] Set `COUCHDB_SECRET` / `COUCHDB_COOKIE` to the SAME values on every node before first start
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 5984
- [ ] Review the [backup guide](https://docs.couchdb.org/en/stable/maintenance/backups.html) for the data volumes
- [ ] Consider a load balancer in front of the cluster for production workloads

## Useful Commands

```bash
# Node membership
curl -u admin:yourpassword http://localhost:5984/_membership

# Cluster health
curl -u admin:yourpassword http://localhost:5984/_cluster_setup

# Check replication / databases
curl -u admin:yourpassword http://localhost:5984/_all_dbs
```

## Resources

- [CouchDB Documentation](https://docs.couchdb.org/en/stable/)
- [CouchDB Docker Image](https://hub.docker.com/_/couchdb)
- [Cluster Setup](https://docs.couchdb.org/en/stable/setup/cluster.html)
- [Fauxton](https://docs.couchdb.org/en/stable/fauxton/index.html)
