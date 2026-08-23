# n8n

[n8n](https://n8n.io/) is a fair-code workflow automation tool that lets you connect 400+ services
through a visual editor. This stack runs the official `n8nio/n8n` image with two named volumes
(workflow data and shared files), a custom network, and the editor bound to localhost by default.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port, hostname, or timezone. The image is pinned to
`n8nio/n8n:2.34.4` by default — bump `N8N_IMAGE` to update.

### 2. Start n8n

```bash
docker compose up -d
```

### 3. Verify n8n is Running

```bash
docker compose ps
```

The `n8n` service should show as "healthy". The healthcheck curls the built-in `/healthz` endpoint,
which returns `{"status":"ok"}` when the editor is ready.

### 4. Open the Editor

Open http://localhost:5678 in your browser. There is no default login — on first run you are asked
to create an owner account directly in the editor.

### 5. Stop n8n

```bash
docker compose down
# Remove the named volumes too (deletes all workflows and credentials):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                | Required | Description                                                      |
| ----------------------- | -------- | ---------------------------------------------------------------- |
| `N8N_IMAGE`             | ❌       | Image tag (default `n8nio/n8n:2.34.4`)                           |
| `N8N_HOST`              | ❌       | Hostname used in the editor UI (default `localhost`)             |
| `N8N_PROTOCOL`          | ❌       | `http` or `https` (default `http`)                               |
| `N8N_PORT`              | ❌       | Container port (fixed at `5678`)                                 |
| `WEBHOOK_URL`           | ❌       | Public webhook base URL (default `http://localhost`)             |
| `N8N_NODE_ENV`          | ❌       | `dev` or `production` (default `dev`)                            |
| `N8N_PORT_EXTERNAL`     | ❌       | Host port (default `5678`, bound to 127.0.0.1)                   |
| `N8N_TZ`                | ❌       | Timezone for schedule/cron triggers (default `UTC`)              |

### Volumes

| Volume                  | Purpose                                        |
| ----------------------- | ---------------------------------------------- |
| `n8n_data:/home/node/.n8n` | Workflows, credentials, settings, database  |
| `n8n_files:/files`         | Shared file storage available to workflows  |

### Ports

| Port | Service        | Access                             |
| ---- | -------------- | ---------------------------------- |
| 5678 | Editor/WebUI   | http://localhost:5678 (LOCAL only) |

## Production Considerations

### 1. Set Hostname, Protocol, and Webhook URL

When exposing n8n publicly (directly or behind a reverse proxy), update `.env`:

```bash
N8N_HOST=n8n.example.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.example.com
N8N_NODE_ENV=production
```

If TLS is terminated at a reverse proxy, keep the stack bound to `127.0.0.1` and proxy traffic to it.

### 2. Bind Mount for Data

Uncomment the bind mount in `docker-compose.yml` for easier backup control:

```yaml
volumes:
  - /data/n8n:/home/node/.n8n
```

The container runs as UID `1000` (`node`). If you switch to a bind mount, ensure the host directory
is writable by that UID:

```bash
sudo chown -R 1000:1000 /data/n8n
```

### 3. Resource Limits

n8n is a Node.js process that can use significant memory with many active workflows. Uncomment and
tune the `deploy.resources` block in `docker-compose.yml`.

### 4. Restart Policy

Containers stop when the host restarts (repo convention — no `restart:` policy is set). If you want
n8n to survive reboots, add to the service:

```yaml
restart: unless-stopped
```

### 5. Postgres for Production

By default n8n uses SQLite (`/home/node/.n8n`), which is fine for a single instance. For production
multi-user use, point n8n at a dedicated PostgreSQL database by adding to the service environment:

```yaml
environment:
  DB_TYPE: postgresdb
  DB_POSTGRESDB_HOST: db
  DB_POSTGRESDB_DATABASE: n8n
  DB_POSTGRESDB_USER: n8n
  DB_POSTGRESDB_PASSWORD: changeme
```

(Deploy a PostgreSQL service alongside n8n — see the [postgresql](https://github.com/GLinBoy/docker-composes/tree/main/postgresql) stack.)

## Backups

The `n8n_data` volume contains everything (workflows, credentials, SQLite DB). Back it up directly:

```bash
docker run --rm -v n8n_n8n_data:/data -v "$PWD":/backup alpine tar czf /backup/n8n-backup-$(date +%F).tar.gz -C /data .
```

## Troubleshooting

### Container is unhealthy

Check the logs:

```bash
docker compose logs n8n
```

Common issues:

- First start is still building the workflow index — give it up to 30s
- Port already in use — change `N8N_PORT_EXTERNAL` in `.env`
- Volume permissions (bind mounts only) — ensure the host dir is owned by UID `1000`

### Reset n8n

Remove the named volumes and start fresh (deletes all workflows and credentials):

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f n8n

# Interactive shell inside the container
docker compose exec n8n sh

# Check the health endpoint
curl -s http://localhost:5678/healthz

# Import a workflow from JSON
docker compose exec n8n n8n import:workflow --separate --input=/files/workflow.json

# Stop the stack
docker compose down
```
