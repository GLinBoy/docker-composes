# Apache Spark

[Apache Spark](https://spark.apache.org/) is a unified analytics engine for large-scale data
processing — batch, streaming, SQL, ML, and graph workloads — with in-memory execution. This stack
runs a standalone Spark cluster using the official `apache/spark` image (Spark standalone mode,
launched directly via `spark-class`):

- **spark-master** — coordinates the cluster and hosts the web UI (port 8080)
- **spark-worker-1 / spark-worker-2** — executor nodes that register with the master
- **spark-submit** — an idle interactive shell for submitting jobs to the cluster

All services share the same image tag and are connected via a dedicated Docker network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

By default no secrets are needed. Optionally change:

- `SPARK_IMAGE` — the exact Spark version to run (defaults to `latest` when unset)
- `SPARK_UI_PORT` — host port for the master web UI (default `8080`)
- `SPARK_MASTER_PORT` — host port for the master RPC (default `7077`)
- `SPARK_WORKER_MEMORY` / `SPARK_WORKER_CORES` — per-worker resources (defaults `1G` / `1`)

### 2. Start the Cluster

```bash
docker compose up -d
```

### 3. Verify the Cluster is Running

```bash
docker compose ps
```

All services should show as "healthy". The workers become healthy only once the master reports them
registered.

### 4. Open the Web UI

Open **http://localhost:8080** in your browser. You should see the master dashboard with two
registered workers and their allocated cores/memory.

### 5. Submit a Job

```bash
docker compose exec spark-submit /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  --class org.apache.spark.examples.SparkPi \
  /opt/spark/examples/jars/spark-examples_2.13-4.2.0.jar 10
```

> The exact examples jar version matches `SPARK_IMAGE` — list `/opt/spark/examples/jars/` inside the
> container to find it.

### 6. Stop the Cluster

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention). To
> have the cluster start automatically, uncomment `restart: unless-stopped` on each service.

## Configuration

### Environment Variables

| Variable               | Required | Description                                        |
| ---------------------- | -------- | -------------------------------------------------- |
| `SPARK_IMAGE`          | ❌       | Image tag for all services (defaults to `latest`)  |
| `SPARK_UI_PORT`        | ❌       | Host port for the master web UI (default: `8080`)  |
| `SPARK_MASTER_PORT`    | ❌       | Host port for the master RPC (default: `7077`)     |
| `SPARK_WORKER_MEMORY`  | ❌       | Memory per worker (default: `1G`)                  |
| `SPARK_WORKER_CORES`   | ❌       | Cores per worker (default: `1`)                    |

### Ports

| Port | Service                  | Access                    |
| ---- | ------------------------ | ------------------------- |
| 8080 | Spark Master web UI      | localhost by default      |
| 7077 | Master RPC / drivers     | for workers and submits   |

### Scaling Up

The compose ships with **two workers** by default to keep resource usage low. To add more, duplicate
a `spark-worker-*` service block with a unique `container_name` / `hostname` (e.g.
`spark-worker-3`), `depends_on` the master, and update the worker healthcheck to grep for the new
hostname. Workers auto-register with the master — no further configuration needed.

```yaml
  spark-worker-3:
    image: ${SPARK_IMAGE:-apache/spark:latest}
    container_name: spark-worker-3
    hostname: spark-worker-3
    depends_on:
      spark-master:
        condition: service_healthy
    command:
      - /opt/spark/bin/spark-class
      - org.apache.spark.deploy.worker.Worker
      - spark://spark-master:7077
      - --host
      - spark-worker-3
      - --memory
      - ${SPARK_WORKER_MEMORY:-1G}
      - --cores
      - ${SPARK_WORKER_CORES:-1}
    networks:
      - spark-network
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://spark-master:8080/json/ | grep -q spark-worker-3 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
```

## Updating

1. Bump `SPARK_IMAGE` in `.env` to the next release (e.g. `apache/spark:4.3.0`).
2. Pull and recreate the cluster:

```bash
docker compose pull
docker compose up -d
```

> All four services share the same image variable, so one bump updates the whole cluster.

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` on each service so the cluster starts automatically after a
reboot.

### 2. Security

Standalone Spark does not enable authentication or encryption by default — the master, workers, and
drivers talk plaintext on the internal network. Before exposing Spark beyond localhost:

- Run it on an isolated network (as here) and keep the UI/RPC ports private
- Configure `spark.authenticate` / `spark.authenticate.secret` and TLS (`spark.ssl.*`) via
  `--conf` flags or a custom `spark-defaults.conf` mounted into each container
- Put the master web UI behind a reverse proxy with TLS (see below)

### 3. Persistence

The cluster is ephemeral by design — drivers and executor data are lost on restart. For real
deployments, mount persistent volumes for checkpoints and job artifacts, or submit from the
`spark-submit` container into a cluster running elsewhere.

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block on each service. Keep workers sized so that
`SPARK_WORKER_MEMORY` fits inside the worker container's memory limit.

### 5. Reverse Proxy

Put the master web UI behind one of the reverse-proxy stacks ([Caddy](../caddy/),
[Traefik](../traefik/), [Nginx Proxy Manager](../nginx-proxy-manager/)) for automatic TLS.

## Troubleshooting

### A worker stays unhealthy

```bash
docker compose logs spark-worker-1
```

The healthcheck greps the master's `/json/` endpoint for the worker hostname (`--host`). If it never
appears, the worker likely can't reach the master — confirm the `spark://spark-master:7077` URL and
the `spark-network` membership.

### Port 8080 already in use

Change `SPARK_UI_PORT` in `.env` and re-run `docker compose up -d`. The internal endpoints (`7077`
RPC, `/json/` on 8080) are unaffected — only the host mapping changes.

## Useful Commands

```bash
# View logs
docker compose logs -f spark-master

# List registered workers (JSON from the master)
curl -s http://localhost:8080/json/

# Open a shell on the submit container
docker compose exec spark-submit bash

# Submit a Scala example job
docker compose exec spark-submit /opt/spark/bin/spark-submit --master spark://spark-master:7077 \
  --class org.apache.spark.examples.SparkPi \
  /opt/spark/examples/jars/spark-examples_2.13-4.2.0.jar 10
```

## Resources

- [Apache Spark](https://spark.apache.org/)
- [apache/spark image on Docker Hub](https://hub.docker.com/r/apache/spark)
- [Spark standalone mode docs](https://spark.apache.org/docs/latest/spark-standalone.html)
