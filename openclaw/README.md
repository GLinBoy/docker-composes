# OpenClaw

[OpenClaw](https://openclaw.ai) is a personal AI assistant you run on your own devices. It connects to multiple messaging platforms and provides a unified interface for AI interactions.

## Quick Start

### 1. Create Required Directories

```bash
mkdir -p config workspace auth-secrets
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `OPENCLAW_GATEWAY_TOKEN` - Generate with `openssl rand -hex 32`
- At least one model provider API key (e.g., `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`)

### 3. Create Initial Configuration

Create `config/openclaw.json`:

```json
{
  "agent": {
    "model": "openai/gpt-4o"
  }
}
```

### 4. Start OpenClaw

```bash
docker compose up -d
```

### 5. Verify OpenClaw is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 6. Test the Gateway

```bash
# Check health endpoint
curl http://localhost:18789/healthz

# View logs
docker compose logs -f openclaw-gateway
```

### 7. Stop OpenClaw

```bash
docker compose down
```

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENCLAW_GATEWAY_TOKEN` | ✅ | Authentication token for gateway access |
| `OPENAI_API_KEY` | ⚠️ | OpenAI API key (or other provider) |
| `ANTHROPIC_API_KEY` | ⚠️ | Anthropic API key (alternative) |
| `GEMINI_API_KEY` | ⚠️ | Google Gemini API key (alternative) |
| `OPENCLAW_TZ` | ❌ | Timezone (default: UTC) |

### Volumes

| Volume | Purpose |
|--------|---------|
| `config` | OpenClaw configuration (`openclaw.json`) |
| `workspace` | Agent workspace, skills, and tools |
| `auth-secrets` | Authentication profile encryption keys |

### Ports

| Port | Purpose |
|------|---------|
| 18789 | Gateway API |
| 18790 | Bridge service |
| 3978 | Microsoft Teams channel (optional) |

## Supported Channels

OpenClaw supports multiple messaging platforms:

- WhatsApp
- Telegram
- Slack
- Discord
- Google Chat
- Signal
- iMessage
- IRC
- Microsoft Teams
- Matrix
- Feishu
- LINE
- Mattermost
- Nextcloud Talk
- Nostr
- Synology Chat
- Tlon
- Twitch
- Zalo
- WeChat
- QQ
- WebChat

Configure channel tokens in `.env` and enable them in `openclaw.json`.

## Production Considerations

### Before Deploying to Production:

1. **Generate Strong Gateway Token**
   
   Never use auto-generated tokens in production:
   
   ```bash
   openssl rand -hex 32
   ```

2. **Secure API Keys**
   
   Store all model provider API keys in `.env` (never commit to git).

3. **Resource Limits**
   
   Uncomment and tune the `deploy.resources` blocks in `docker-compose.yml`:
   
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2.0'
         memory: 2G
   ```

4. **Bind Mounts for Data**
   
   Consider using bind mounts instead of named volumes for easier backup:
   
   ```yaml
   volumes:
     - /data/openclaw/config:/home/node/.openclaw
     - /data/openclaw/workspace:/home/node/.openclaw/workspace
     - /data/openclaw/auth-secrets:/home/node/.config/openclaw
   ```

5. **Sandbox Isolation**
   
   For production with multiple users/channels, enable Docker sandbox:
   
   - Uncomment the Docker socket mount
   - Uncomment `group_add` with your Docker GID
   - Set `DOCKER_GID` in `.env`: `stat -c '%g' /var/run/docker.sock`

6. **Network Security**
   
   - Default gateway binds to LAN; use `--bind localhost` for local-only
   - For remote access, configure firewall rules for exposed ports
   - Consider using a reverse proxy (Caddy, Nginx) with TLS

7. **Timezone Configuration**
   
   Set `OPENCLAW_TZ` to your server's timezone for correct scheduling.

8. **Backup Configuration**
   
   Regularly backup the `config`, `workspace`, and `auth-secrets` volumes.

## Troubleshooting

### Gateway won't start

Check the logs:
```bash
docker compose logs openclaw-gateway
```

Common issues:
- Missing `OPENCLAW_GATEWAY_TOKEN` (if binding beyond localhost)
- Invalid `openclaw.json` syntax
- Port conflicts (check if ports 18789, 18790 are already in use)

### Model provider errors

- Verify API keys are correct in `.env`
- Check provider status/outages
- Ensure network connectivity from container

### Channel connection issues

- Verify channel tokens/bot credentials
- Check channel-specific documentation for setup requirements
- Review channel logs: `docker compose logs openclaw-gateway | grep -i <channel>`

### Sandbox issues

- Ensure Docker socket is accessible
- Verify `DOCKER_GID` matches host's docker group
- Check container has `docker` command available

## Useful Commands

```bash
# View all logs
docker compose logs -f

# View gateway logs only
docker compose logs -f openclaw-gateway

# Restart gateway
docker compose restart openclaw-gateway

# Access CLI inside container
docker compose exec openclaw-cli node dist/index.js gateway status

# Rebuild configuration
docker compose exec openclaw-gateway node dist/index.js gateway reload

# Clean restart (loses all data)
docker compose down -v
docker compose up -d
```

## OpenClaw CLI

The CLI service shares the gateway's network namespace and can be used for management:

```bash
# Check gateway status
docker compose exec openclaw-cli node dist/index.js gateway status

# List active sessions
docker compose exec openclaw-cli node dist/index.js sessions list

# Send a test message
docker compose exec openclaw-cli node dist/index.js message send --target <target> --message "Hello"
```

## Resources

- [Official Documentation](https://docs.openclaw.ai/)
- [Getting Started Guide](https://docs.openclaw.ai/start/getting-started)
- [Configuration Reference](https://docs.openclaw.ai/gateway/configuration)
- [Channel Setup](https://docs.openclaw.ai/channels)
- [Security Guide](https://docs.openclaw.ai/gateway/security)
- [GitHub Repository](https://github.com/openclaw/openclaw)
- [Discord Community](https://discord.gg/clawd)