# Paperless-AI

[Paperless-AI](https://clusterzx.github.io/paperless-ai/) is an AI-powered extension for
[Paperless-ngx](https://docs.paperless-ngx.com/) that adds automatic document classification, smart
tagging, and semantic search using OpenAI-compatible APIs and Ollama. It enables fully automated
document workflows, contextual chat, and manual processing — all through an intuitive web interface.
This stack runs the official `clusterzx/paperless-ai` image with a named volume and a custom network.

> ⚠️ **Note:** This project is currently not maintained upstream (see the
> [project README](https://github.com/clusterzx/paperless-ai)). Use it with that in mind.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port. The image is pinned to `clusterzx/paperless-ai:3.0.9` by
default — bump `PAPERLESS_AI_IMAGE` to update.

### 2. Start Paperless-AI

```bash
docker compose up -d
```

### 3. Verify Paperless-AI is Running

```bash
docker compose ps
```

The `paperless-ai` service should show as "healthy".

### 4. Connect to Paperless-ngx

Open http://localhost:3000 in your browser. On first launch you are prompted to set up the
Paperless-ngx connection:

- **Paperless-ngx API URL** — e.g. `http://<paperless-host>:8000/api`
- **Paperless-ngx API token** — create one in Paperless-ngx under *Settings → API*
  (use `openssl rand -hex 24` to generate one)
- **AI provider** — OpenAI, Ollama, or any OpenAI-compatible API

**After completing setup, restart the container once** so the RAG index can be built:

```bash
docker compose restart
```

### 5. Stop Paperless-AI

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                          | Required | Description                                              |
| --------------------------------- | -------- | -------------------------------------------------------- |
| `PAPERLESS_AI_IMAGE`              | ❌       | Image tag (default `clusterzx/paperless-ai:3.0.9`)       |
| `PAPERLESS_AI_PORT`               | ❌       | Host port (default `3000`, maps to 3000)                 |
| `PAPERLESS_AI_TZ`                 | ❌       | Container timezone (default `UTC`)                       |
| `PAPERLESS_AI_RAG_SERVICE_URL`    | ❌       | RAG service URL (default `http://localhost:8000`)        |
| `PAPERLESS_AI_RAG_SERVICE_ENABLED`| ❌       | Enable the RAG service (default `true`)                  |

### Volumes

| Volume                         | Purpose                              |
| ------------------------------ | ------------------------------------ |
| `paperless-ai_data:/app/data`  | Application database and data        |

### Ports

| Port | Service             | Access               |
| ---- | ------------------- | -------------------- |
| 3000 | Paperless-AI web UI | localhost by default |

## Production Considerations

### Before Deploying to Production:

1. **Expose Ports Securely**

   By default the UI binds to all interfaces on `0.0.0.0`. Put Paperless-AI behind a reverse proxy
   (see the [nginx-proxy-manager](../nginx-proxy-manager/), [Caddy](../caddy/), or
   [Traefik](../traefik/) stacks) and do not expose port 3000 directly to the internet.

2. **Bind Mount for Data**

   Uncomment the bind mount in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/paperless-ai:/app/data
   ```

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. The image ships a Python
   RAG service in addition to the Node.js app, so budget at least 1GB of memory.

4. **Restart Policy**

   Uncomment `restart: unless-stopped` in `docker-compose.yml` so the container comes back after a
   host reboot or crash.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs paperless-ai
```

### Not finding documents from Paperless-ngx

Verify the Paperless-ngx API URL and token in the Paperless-AI web UI, then restart the container to
rebuild the index. Also confirm the Paperless-ngx instance is reachable from the Paperless-AI host.

### Port 3000 already in use

Change `PAPERLESS_AI_PORT` in `.env` and re-run `docker compose up -d`.

### Reset the data

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f paperless-ai

# Back up the data volume
docker run --rm -v paperless-ai_paperless-ai_data:/data -v "$PWD":/backup alpine tar czf /backup/paperless-ai_data.tar.gz -C /data .
```

## Resources

- [Paperless-AI documentation](https://clusterzx.github.io/paperless-ai/)
- [Installation wiki](https://github.com/clusterzx/paperless-ai/wiki/2.-Installation)
- [Paperless-ngx](https://docs.paperless-ngx.com/)
- [Official clusterzx/paperless-ai image on Docker Hub](https://hub.docker.com/r/clusterzx/paperless-ai)
