# MinIO

[MinIO](https://min.io/) is a high-performance, S3-compatible object storage server. It is
designed to run as a distributed cluster, providing erasure coding and data protection
across multiple servers and drives.

This stack runs a 2-node MinIO distributed cluster (each node with 2 data drives — 4 drives
total, the minimum for erasure coding), fronted by an nginx load balancer that exposes the
S3 API and the web console through single ports.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `MINIO_ROOT_USER` - MinIO admin username (min. 8 characters)
- `MINIO_ROOT_PASSWORD` - MinIO admin password (min. 8 characters)

Optionally change:

- `MINIO_PORT` - the host port for the S3 API (default `9000`)
- `MINIO_CONSOLE_PORT` - the host port for the web console (default `9001`)

### 2. Start MinIO

```bash
docker compose up -d
```

The `docker compose up` will pull the images, create the volumes, and start all five
containers. The two MinIO nodes must both become healthy before nginx starts routing.

### 3. Verify MinIO is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Access the Console

Open http://localhost:9001 and log in with `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`.

### 5. Use the S3 API

The S3 API is available at http://localhost:9000 (through the nginx load balancer). For
example, with the `mc` client:

```bash
mc alias set local http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
mc ls local
```

### 6. View Logs

```bash
docker compose logs -f minio-0
```

### 7. Stop MinIO

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have MinIO start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable              | Required | Description                                                          |
| --------------------- | -------- | -------------------------------------------------------------------- |
| `MINIO_ROOT_USER`     | ✅       | MinIO admin username (min. 8 characters)                             |
| `MINIO_ROOT_PASSWORD` | ✅       | MinIO admin password (min. 8 characters)                             |
| `MINIO_IMAGE`         | ❌       | MinIO image (exact-pinned, default: `minio/minio:RELEASE.2025-09-07T16-13-09Z`) |
| `MINIO_NGINX_IMAGE`   | ❌       | nginx load balancer image (exact-pinned, default: `nginx:1.25.1-alpine`) |
| `MINIO_PORT`          | ❌       | Host port for the S3 API (default: `9000`)                           |
| `MINIO_CONSOLE_PORT`  | ❌       | Host port for the web console (default: `9001`)                      |
| `TZ`                  | ❌       | Timezone (default: `Etc/UTC`)                                        |

### Volumes

Each MinIO node has two dedicated data volumes:

| Volume         | Purpose                              |
| -------------- | ------------------------------------ |
| `minio0-data1` | Node `minio-0`, first drive          |
| `minio0-data2` | Node `minio-0`, second drive         |
| `minio1-data1` | Node `minio-1`, first drive          |
| `minio1-data2` | Node `minio-1`, second drive         |

### Ports

| Port | Purpose                        |
| ---- | ------------------------------ |
| 9000 | S3 API (via nginx)             |
| 9001 | Web console (via nginx)        |

## Architecture

```
            +--------+
 client ──► |  nginx |  (load balancer, ports 9000/9001)
            +---+----+
                |
        +-------+-------+
        |               |
   +----+----+    +----+----+
   | minio-0 |    | minio-1 |
   |  data1  |    |  data1  |
   |  data2  |    |  data2  |
   +---------+    +---------+
```

MinIO nodes form a distributed cluster using the hostnames `minio-0` and `minio-1`. Each
node serves two drives; with 4 drives total, MinIO uses erasure coding so the cluster can
tolerate the loss of one drive.

## Scaling Up

The stack ships with 2 nodes by default to keep resource usage low. To add a third node:

1. Add a new data volume at the bottom of `docker-compose.yml`:

```yaml
  minio2-data1:
    driver: local
  minio2-data2:
    driver: local
```

2. Add the new service after `minio-1`:

```yaml
  minio-2:
    <<: *minio-common
    container_name: minio-2
    hostname: minio-2
    volumes:
      - minio2-data1:/data1
      - minio2-data2:/data2
```

3. Add the new node to the cluster command in the `x-minio-common` anchor:

```yaml
  command: server --console-address ":9001"
    http://minio-0/data1 http://minio-0/data2
    http://minio-1/data1 http://minio-1/data2
    http://minio-2/data1 http://minio-2/data2
```

4. Add the new node to the nginx upstreams in `nginx.conf`:

```nginx
    upstream minio {
        server minio-0:9000;
        server minio-1:9000;
        server minio-2:9000;
    }

    upstream console {
        ip_hash;
        server minio-0:9001;
        server minio-1:9001;
        server minio-2:9001;
    }
```

5. Recreate the stack:

```bash
docker compose up -d
```

> ⚠️ A distributed MinIO cluster uses all volumes from the first start. Adding drives later
> changes the erasure coding layout and is not supported as an online operation — plan the
> final size before first start, or use a fresh data set when scaling.

## Updating

1. Bump `MINIO_IMAGE` in `.env` to the next release (e.g. `RELEASE.2025-10-01T00-00-00Z`).
2. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set strong `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` in `.env`
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Place each node's drives on separate physical disks for real erasure-coding protection
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing ports 9000/9001
- [ ] Review the [MinIO backup docs](https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-multi-node.html) for multi-node deployment and backups
