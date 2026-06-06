# Ollama + Open WebUI

## About

- **Ollama** — Run local LLMs (Llama, Mistral, Gemma, etc.)
  ([website](https://ollama.com))
- **Open WebUI** — ChatGPT-like interface for Ollama
  ([website](https://github.com/open-webui/open-webui))

## Local Usage

```bash
cp .env.example .env
# Optionally set WEBUI_SECRET_KEY in .env

docker compose up -d
docker compose ps --format "table {{.Name}}\t{{.Status}}"
```

After startup:
- Open WebUI: http://localhost:3000
- Ollama API: http://localhost:11434

Pull a model via the Open WebUI admin panel or directly:

```bash
docker compose exec ollama ollama pull llama3.2
```

## Verification

```bash
# Both services should show "healthy"
docker compose ps --format "table {{.Name}}\t{{.Status}}"

# Check Ollama API
docker compose exec ollama ollama list

# Check Open WebUI health
curl -sf http://localhost:3000/health
```

## Tear Down

```bash
docker compose down -v
```

## Server Checklist

| Action | Description |
|---|---|
| 🔒 **Set WEBUI_SECRET_KEY** | Generate with `openssl rand -hex 64`, add to `.env` |
| 🎮 **Enable GPU acceleration** | Uncomment the `deploy.resources` block in the ollama service |
| 🔐 **Reverse proxy** | Put behind Nginx/Caddy/Traefik with HTTPS |
| 💾 **Back up data** | `ollama/` and `open_webui/` directories contain all state |
