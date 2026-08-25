# paperless-gpt

[paperless-gpt](https://github.com/icereed/paperless-gpt) pairs with
[Paperless-ngx](https://docs.paperless-ngx.com/) to generate AI-powered document titles, tags,
correspondents, and created dates, and can supercharge OCR with LLMs for higher accuracy on tricky
scans. It supports OpenAI, Ollama, and other LLM backends, plus multiple OCR providers. This stack
runs the official `icereed/paperless-gpt` image with named volumes and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Fill in the required values in `.env`:

- `PAPERLESS_BASE_URL` — URL of your Paperless-ngx instance as seen from this container
- `PAPERLESS_API_TOKEN` — generate one in Paperless-ngx → Settings → API
- `LLM_PROVIDER`, `LLM_MODEL`, and the matching API key (e.g. `OPENAI_API_KEY`)

The image is pinned to `icereed/paperless-gpt:v0.27.0` by default — bump `PAPERLESS_GPT_IMAGE` to update.

### 2. Start paperless-gpt

```bash
docker compose up -d
```

### 3. Verify paperless-gpt is Running

```bash
docker compose ps
```

The `paperless-gpt` service should show as "healthy".

### 4. Access the Web UI

Open http://localhost:8080 in your browser. On first launch the default prompts are copied into the
`prompts` volume and can be customized in the web UI under **Settings**.

### 5. Stop paperless-gpt

```bash
docker compose down
# Remove the named volumes too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                | Required | Description                                                      |
| ----------------------- | -------- | ---------------------------------------------------------------- |
| `PAPERLESS_GPT_IMAGE`   | ❌       | Image tag (default `icereed/paperless-gpt:v0.27.0`)              |
| `PAPERLESS_GPT_PORT`    | ❌       | Host port (default `8080`, bound to 127.0.0.1)                   |
| `PAPERLESS_GPT_TZ`      | ❌       | Container timezone (default `UTC`)                               |
| `PUID` / `PGID`         | ❌       | Non-root user/group IDs (default `10001`)                        |
| `PAPERLESS_BASE_URL`    | ✅       | URL of your Paperless-ngx instance                               |
| `PAPERLESS_API_TOKEN`   | ✅       | Paperless-ngx API token                                          |
| `PAPERLESS_PUBLIC_URL`  | ❌       | Public URL of Paperless (if different from base)                 |
| `MANUAL_TAG`            | ❌       | Tag for manual processing (default `paperless-gpt`)              |
| `AUTO_TAG`              | ❌       | Tag for auto processing (default `paperless-gpt-auto`)           |
| `FAIL_TAG`              | ❌       | Tag for failed updates (default `paperless-gpt-failed`)          |
| `LLM_PROVIDER`          | ✅       | LLM backend (`openai`, `ollama`, `googleai`, `mistral`, `anthropic`) |
| `LLM_MODEL`             | ✅       | Model name (e.g. `gpt-4o`, `qwen3:8b`)                           |
| `OPENAI_API_KEY`        | ✅       | OpenAI API key (when `LLM_PROVIDER=openai`)                      |
| `OLLAMA_HOST`           | ❌       | Ollama server URL (when `LLM_PROVIDER=ollama`)                   |
| `LLM_LANGUAGE`          | ❌       | Prompt language (default `English`)                              |
| `OCR_PROVIDER`          | ❌       | OCR provider (default `llm`)                                     |
| `LOG_LEVEL`             | ❌       | Log level (default `info`)                                       |

For the full list of optional settings (OCR providers, PDF upload, custom fields, etc.), see the
[upstream documentation](https://github.com/icereed/paperless-gpt#configuration).

### Volumes

| Volume                          | Purpose                                    |
| ------------------------------- | ------------------------------------------ |
| `paperless-gpt_data:/app/db`    | SQLite modification history and OCR state  |
| `paperless-gpt_config:/app/config` | Saved settings and custom field config   |
| `paperless-gpt_prompts:/app/prompts` | Custom prompt templates (persisted)   |

### Ports

| Port | Service                 | Access                         |
| ---- | ----------------------- | ------------------------------ |
| 8080 | paperless-gpt web UI    | `127.0.0.1:8080` by default    |

## Production Considerations

> **⚠️ No built-in authentication.** paperless-gpt's web UI and `/api/*` endpoints are open to
> anyone who can reach the port. Anyone who can reach it can rewrite documents in your connected
> Paperless-ngx instance and trigger LLM/OCR jobs against your API keys.

### Before Deploying to Production:

1. **Put it Behind an Authenticated Reverse Proxy**

   Do not expose port 8080 directly. Put paperless-gpt behind a reverse proxy that adds
   authentication (e.g. [Authentik](../authentik/), Authelia, or Basic Auth) or restrict it to a
   VPN/Tailscale network. See the [nginx-proxy-manager](../nginx-proxy-manager/),
   [Caddy](../caddy/), or [Traefik](../traefik/) stacks.

2. **Bind Mounts for Data**

   Uncomment the bind mounts in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/paperless-gpt/db:/app/db
     - /data/paperless-gpt/config:/app/config
     - /data/paperless-gpt/prompts:/app/prompts
   ```

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

4. **Restart Policy**

   Uncomment `restart: unless-stopped` in `docker-compose.yml` so the container comes back after a
   host reboot or crash.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs paperless-gpt
```

### Not connecting to Paperless-ngx

Verify `PAPERLESS_BASE_URL` is reachable from this container. If the Paperless-ngx stack is on a
different Docker network, either attach this container to that network or expose Paperless-ngx to
this stack (see the paperless-ngx stack's README).

### Working with a local Ollama

On Linux, set `OLLAMA_HOST` to `http://host.docker.internal:11434` and add `extra_hosts:
["host.docker.internal:host-gateway"]` to reach an Ollama server running on the host.

### Port 8080 already in use

Change `PAPERLESS_GPT_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f paperless-gpt

# Back up the data volumes
docker run --rm -v paperless-gpt_paperless-gpt_data:/data -v "$PWD":/backup alpine tar czf /backup/paperless-gpt_data.tar.gz -C /data .
docker run --rm -v paperless-gpt_paperless-gpt_config:/data -v "$PWD":/backup alpine tar czf /backup/paperless-gpt_config.tar.gz -C /data .
docker run --rm -v paperless-gpt_paperless-gpt_prompts:/data -v "$PWD":/backup alpine tar czf /backup/paperless-gpt_prompts.tar.gz -C /data .
```

## Resources

- [paperless-gpt repository](https://github.com/icereed/paperless-gpt)
- [paperless-gpt documentation](https://github.com/icereed/paperless-gpt#configuration)
- [Paperless-ngx](https://docs.paperless-ngx.com/)
- [Official icereed/paperless-gpt image on Docker Hub](https://hub.docker.com/r/icereed/paperless-gpt)
