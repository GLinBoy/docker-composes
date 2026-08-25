# Ollama + Open WebUI

[Ollama](https://ollama.com/) is an open-source tool for running large language models (Llama,
Mistral, Gemma, Qwen, etc.) locally on CPU or GPU. [Open WebUI](https://openwebui.com/) is a
ChatGPT-style web interface for Ollama and other LLM backends.

This stack runs the official
[`ollama/ollama` image](https://hub.docker.com/r/ollama/ollama) and the official
[`ghcr.io/open-webui/open-webui` image](https://github.com/open-webui/open-webui) on a private
network. Open WebUI talks to Ollama over the internal network; only the web UI is exposed on the
host.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum `WEBUI_SECRET_KEY` (generate with `openssl rand -hex 64`). The
defaults work out of the box for a local setup.

### 2. Start the Stack

```bash
docker compose up -d
```

### 3. Verify Both Services are Healthy

```bash
docker compose ps
```

Both `ollama` and `open-webui` should show as "healthy".

### 4. Pull a Model

```bash
docker compose exec ollama ollama pull llama3.2
```

or pull a model from the Open WebUI admin panel.

### 5. Access the Interface

- Open WebUI: http://localhost:3000
- Ollama API: http://localhost:11434

### 6. Stop the Stack

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have the stack start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable               | Required | Description                                                            |
| ---------------------- | -------- | ---------------------------------------------------------------------- |
| `OLLAMA_IMAGE`         | ❌       | Ollama image tag (default `ollama/ollama:latest` when unset)           |
| `OPEN_WEBUI_IMAGE`     | ❌       | Open WebUI image tag (default `ghcr.io/open-webui/open-webui:latest` when unset) |
| `OLLAMA_PORT`          | ❌       | Host port for the Ollama API (default `11434`)                         |
| `OPEN_WEBUI_PORT`      | ❌       | Host port for the Open WebUI UI (default `3000`)                       |
| `TZ`                   | ❌       | Timezone (default `Etc/UTC`)                                           |
| `OLLAMA_API_BASE_URL`  | ❌       | Ollama URL as seen from Open WebUI (default `http://ollama:11434/api`) |
| `WEBUI_SECRET_KEY`     | ✅       | Session signing key (`openssl rand -hex 64`)                           |

### Volumes

| Volume            | Purpose                                  |
| ----------------- | ---------------------------------------- |
| `ollama_data`     | Pulled models, manifests, and config     |
| `open_webui_data` | Database, uploads, vector store, caches  |

### Ports

| Port | Purpose              |
| ---- | -------------------- |
| 11434| Ollama HTTP API      |
| 3000 | Open WebUI interface |

Both ports are bound to `127.0.0.1` only by default. See the server checklist below before
exposing them publicly.

## Updating

1. Check the [Ollama releases](https://github.com/ollama/ollama/releases) and
   [Open WebUI releases](https://github.com/open-webui/open-webui/releases) pages.
2. Bump `OLLAMA_IMAGE` / `OPEN_WEBUI_IMAGE` in `.env` to the next tag.
3. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

## Migrating Existing Data

This stack previously mounted the local directories `./ollama` and `./open_webui` directly. If
you have models or data in those directories and want to keep them:

1. Start the stack once so the named volumes are created:

   ```bash
   docker compose up -d
   ```

2. Copy the old data into the volumes:

   ```bash
   docker run --rm -v ollama_ollama_data:/target -v "$PWD/ollama":/src \
     alpine sh -c "cp -a /src/. /target/"
   docker run --rm -v ollama_open_webui_data:/target -v "$PWD/open_webui":/src \
     alpine sh -c "cp -a /src/. /target/"
   ```

3. Restart the stack and verify your models appear:

   ```bash
   docker compose restart
   docker compose exec ollama ollama list
   ```

## Server Checklist

Before deploying to a production server:

- [ ] Set `WEBUI_SECRET_KEY` in `.env` (`openssl rand -hex 64`)
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] For GPU inference, install the
      [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
      and uncomment the `devices` block in the `ollama` service
- [ ] Keep the stack behind a reverse proxy (e.g. [Caddy](../caddy/), [Nginx](../nginx/),
      [Traefik](../traefik/)) instead of exposing ports directly
- [ ] Back up the `ollama_data` and `open_webui_data` volumes (or use bind mounts) — these hold
      all models and user data

## Useful Commands

```bash
# View logs
docker compose logs -f ollama

# List installed models
docker compose exec ollama ollama list

# Pull a model
docker compose exec ollama ollama pull llama3.2

# Open WebUI health check
curl -sf http://localhost:3000/health
```

## Resources

- [Ollama website](https://ollama.com/)
- [Ollama documentation](https://github.com/ollama/ollama/tree/main/docs)
- [ollama/ollama image on Docker Hub](https://hub.docker.com/r/ollama/ollama)
- [Open WebUI website](https://openwebui.com/)
- [Open WebUI GitHub repository](https://github.com/open-webui/open-webui)
