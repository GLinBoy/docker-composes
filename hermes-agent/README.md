# Hermes Agent

[Hermes Agent](https://hermes-agent.nousresearch.com/) is a self-improving AI agent built by [Nous Research](https://nousresearch.com). It's the only agent with a built-in learning loop — it creates skills from experience, improves them during use, and builds a deepening model of who you are across sessions.

## Quick Start

### 1. Create Hermes Data Directory

```bash
mkdir -p ~/.hermes
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set:

- `HERMES_UID` and `HERMES_GID` - Run: `echo "HERMES_UID=$(id -u)" && echo "HERMES_GID=$(id -g)"`
- At least one LLM provider API key (e.g., `OPENROUTER_API_KEY`)

### 3. Start Hermes

```bash
docker compose up -d
```

### 4. Verify Hermes is Running

```bash
docker compose ps
```

Both services should show as "healthy".

### 5. Access Hermes

**CLI Mode:**
```bash
docker compose exec hermes-gateway hermes
```

**Dashboard (Localhost):**
```bash
# Open in browser
open http://localhost:9119
# Or via SSH tunnel for remote servers:
# ssh -L 9119:localhost:9119 user@host
```

**Messaging Platforms:**
Configure platform tokens in `.env` and run:
```bash
docker compose exec hermes-gateway hermes gateway setup
```

### 6. Stop Hermes

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have Hermes start automatically, add `restart: unless-stopped` to
> the services.

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `HERMES_IMAGE` | ❌ | Image tag (default `nousresearch/hermes-agent:latest`) |
| `HERMES_UID` | ✅ | Host user ID for file permissions |
| `HERMES_GID` | ✅ | Host group ID for file permissions |
| `OPENROUTER_API_KEY` | ⚠️ | OpenRouter API key (or other LLM provider) |
| `TELEGRAM_BOT_TOKEN` | ❌ | Telegram bot token (for messaging) |
| `SLACK_BOT_TOKEN` | ❌ | Slack bot token (for messaging) |

### Volumes

| Volume | Purpose |
|--------|---------|
| `~/.hermes:/opt/data` | Hermes data, config, skills, and memories |

### Ports

Hermes uses **host network mode** by default for easier setup. Services bind to:

| Port | Service | Access |
|------|---------|--------|
| 9119 | Dashboard | localhost only (use SSH tunnel for remote) |
| 3978 | Microsoft Teams | Optional (if enabled) |

## Supported Platforms

Hermes connects to multiple messaging platforms:

- **Telegram** - Bot via @BotFather
- **Discord** - Bot via Discord Developer Portal
- **Slack** - Bot via Slack App settings
- **WhatsApp** - Built-in Baileys bridge
- **Signal** - Via signal-cli
- **Microsoft Teams** - Bot Framework registration
- **Google Chat** - Cloud Pub/Sub integration
- **Email** - IMAP/SMTP
- **CLI** - Interactive terminal UI

## Features

### Core Capabilities

- **Self-Improving** - Creates skills from experience, improves during use
- **Multi-Platform** - Telegram, Discord, Slack, WhatsApp, Signal, CLI
- **Persistent Memory** - Cross-session recall with FTS5 search
- **Scheduled Automations** - Built-in cron scheduler
- **Parallel Execution** - Spawn isolated subagents for parallel work
- **Six Terminal Backends** - local, Docker, SSH, Singularity, Modal, Daytona

### Skills System

- Procedural memory with agent-curated learning
- Autonomous skill creation after complex tasks
- Skills self-improve during use
- Compatible with [agentskills.io](https://agentskills.io) standard

### Voice & Browser

- Voice memo transcription (Whisper)
- Cloud browser automation (Browserbase)
- Image generation (FAL.ai)
- Web search & extract (Exa, Firecrawl, Parallel)

## Production Considerations

### Before Deploying to Production:

1. **Set Correct UID/GID**
   
   Critical for file permissions:
   
   ```bash
   HERMES_UID=$(id -u)
   HERMES_GID=$(id -g)
   ```

2. **Secure API Keys**
   
   Store all API keys in `.env` (never commit to git).

3. **Resource Limits**
   
   Uncomment and tune the `deploy.resources` blocks in `docker-compose.yml`:
   
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2.0'
         memory: 4G
   ```

4. **Bind Mount for Data**
   
   Consider using a bind mount instead of named volume:
   
   ```yaml
   volumes:
     - /data/hermes:/opt/data
   ```

5. **Dashboard Security**
   
   Dashboard binds to `127.0.0.1` by default. For remote access:
   
   - **Recommended**: SSH tunnel: `ssh -L 9119:localhost:9119 user@host`
   - **Alternative**: Reverse proxy with authentication (Caddy, Nginx)
   - **⚠️ Never**: Expose dashboard directly without auth

6. **API Server (Optional)**
   
   To expose the OpenAI-compatible API server:
   
   - Uncomment `API_SERVER_HOST=0.0.0.0`
   - Set strong `API_SERVER_KEY` (generate with `openssl rand -hex 32`)
   - Put behind reverse proxy with TLS

7. **Network Mode**
   
   Default uses `network_mode: host` for simplicity. For isolation:
   
   - Remove `network_mode: host`
   - Add explicit port mappings
   - Use custom network

8. **Backup Configuration**
   
   Regularly backup `~/.hermes` directory (contains all data).

## Troubleshooting

### Gateway won't start

Check the logs:
```bash
docker compose logs hermes-gateway
```

Common issues:
- Missing `HERMES_UID`/`HERMES_GID` (file permission errors)
- No LLM provider API key configured
- Port conflicts (if not using host network mode)

### File permission errors

Ensure `HERMES_UID` and `HERMES_GID` match your host user:
```bash
echo "HERMES_UID=$(id -u)" && echo "HERMES_GID=$(id -g)"
```

### Dashboard not accessible

Dashboard binds to `127.0.0.1` by default. For remote access:
```bash
ssh -L 9119:localhost:9119 user@host
```

### Platform connection issues

- Verify bot tokens/credentials in `.env`
- Check platform-specific documentation
- Review logs: `docker compose logs hermes-gateway | grep -i <platform>`

## Useful Commands

```bash
# View all logs
docker compose logs -f

# View gateway logs only
docker compose logs -f hermes-gateway

# Access CLI inside container
docker compose exec hermes-gateway hermes

# Start gateway (if not running)
docker compose exec hermes-gateway hermes gateway start

# Setup messaging platforms
docker compose exec hermes-gateway hermes gateway setup

# Change model
docker compose exec hermes-gateway hermes model

# View skills
docker compose exec hermes-gateway hermes skills

# Rebuild configuration
docker compose exec hermes-gateway hermes config reload

# Clean restart (loses all data)
docker compose down
rm -rf ~/.hermes
docker compose up -d
```

## Hermes CLI Commands

Once inside the container:

```bash
# Interactive CLI
hermes

# Gateway management
hermes gateway start
hermes gateway stop
hermes gateway status

# Model selection
hermes model

# Tool configuration
hermes tools

# Skills management
hermes skills
hermes skills install <skill-name>

# Session management
hermes sessions list
hermes sessions history

# Setup wizard
hermes setup
```

## Resources

- [Official Documentation](https://hermes-agent.nousresearch.com/docs/)
- [Quickstart Guide](https://hermes-agent.nousresearch.com/docs/getting-started/quickstart)
- [CLI Usage](https://hermes-agent.nousresearch.com/docs/user-guide/cli)
- [Messaging Gateway](https://hermes-agent.nousresearch.com/docs/user-guide/messaging)
- [Skills System](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills)
- [GitHub Repository](https://github.com/NousResearch/hermes-agent)
- [Discord Community](https://discord.gg/NousResearch)
- [Nous Portal](https://portal.nousresearch.com) - Unified API access