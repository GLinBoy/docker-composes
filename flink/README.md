# Flink

[Apache Flink](https://flink.apache.org/) is an open-source, distributed stream and batch
processing framework. It processes data at high throughput and low latency with exactly-once
state consistency.

This stack runs a minimal two-node Flink cluster using the
[official Flink image](https://hub.docker.com/_/flink): a **JobManager** (coordinates the cluster
and hosts the web UI) and a **TaskManager** (executes the jobs). Both use the same image pinned to
a shared version, connected via a dedicated Docker network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

By default no secrets are needed. Optionally change:

- `FLINK_VERSION` - the exact Flink version to run (defaults to `latest` when unset)
- `FLINK_UI_PORT` - the host port for the web UI (default `8081`)
- `FLINK_JOBMANAGER_RPC_PORT` - the host port for the JobManager RPC (default `6123`)

### 2. Start the Cluster

```bash
docker compose up -d
```

### 3. Verify the Cluster is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Open the Web UI

Open **http://localhost:8081** in your browser. You should see the running cluster with the
TaskManager registered under **Task Managers**.

### 5. Submit a Job

```bash
docker compose exec flink-jobmanager ./bin/flink run \
  /opt/flink/examples/streaming/WordCount.jar
```

### 6. View Logs

```bash
docker compose logs -f flink-taskmanager
```

### 7. Stop the Cluster

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention). To
> have the cluster start automatically, uncomment `restart: unless-stopped` on each service.

## Configuration

### Environment Variables

| Variable                    | Required | Description                                       |
| --------------------------- | -------- | ------------------------------------------------- |
| `FLINK_VERSION`             | ❌       | Exact Flink version (defaults to `latest`)        |
| `FLINK_UI_PORT`             | ❌       | Host port for the web UI (default: `8081`)        |
| `FLINK_JOBMANAGER_RPC_PORT` | ❌       | Host port for the JobManager RPC (default: `6123`) |

### Ports

| Port | Service                          | Access             |
| ---- | -------------------------------- | ------------------ |
| 8081 | Flink Web UI (JobManager)        | localhost by default |
| 6123 | JobManager RPC / Actor system    | for TaskManager    |

### Scaling Up

The compose ships with **one TaskManager** by default to keep resource usage low. To add more
workers, duplicate the `flink-taskmanager` service block with a unique `container_name` (e.g.
`flink-taskmanager-2`) and `depends_on` the JobManager. All TaskManagers register with the same
JobManager and split the workload automatically — no further configuration needed.

```yaml
  flink-taskmanager-2:
    image: flink:${FLINK_VERSION:-latest}
    container_name: flink-taskmanager-2
    depends_on:
      flink-jobmanager:
        condition: service_healthy
    environment:
      - JOB_MANAGER_RPC_ADDRESS=flink-jobmanager
    command: taskmanager
    networks:
      - flink-network
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://flink-jobmanager:8081/taskmanagers || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
```

## Updating

1. Bump `FLINK_VERSION` in `.env` to the next release (e.g. `2.4.0`).
2. Pull and recreate the cluster:

```bash
docker compose pull
docker compose up -d
```

> Both services use the same version variable, so one bump updates the whole cluster.

## Server Checklist

Before deploying to a production server:

- [ ] Enable checkpointing and mount a persistent directory for checkpoints/savepoints
- [ ] Mount a custom `flink-conf.yaml` (see the jobmanager service comment in `docker-compose.yml`)
- [ ] Tune TaskManager memory (`taskmanager.memory.process.size`) in the config for your workload
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Secure the web UI (port 8081) behind a reverse proxy or restrict access by firewall

## Resources

- [Apache Flink](https://flink.apache.org/)
- [Flink Docker image](https://hub.docker.com/_/flink)
- [Flink Docker deployment docs](https://nightlies.apache.org/flink/flink-docs-stable/docs/deployment/resource-providers/standalone/docker/)
- [Flink examples](https://github.com/apache/flink/tree/master/flink-examples/flink-examples-streaming)
