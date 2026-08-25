# OpenClaw

[OpenClaw](https://openclaw.ai/) is a personal AI assistant you run on your own devices. It
connects to multiple messaging platforms and provides a unified interface for AI interactions.

This stack runs the official
[`ghcr.io/openclaw/openclaw` image](https://github.com/openclaw/openclaw) as two services on a
private network: `openclaw-gateway` (the HTTP gateway that hosts the Control UI and connects to
channels) and `openclaw-cli` (an interactive CLI that shares the gateway's network namespace for
management commands).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `OPENCLAW_GATEWAY_TOKEN` — generate with `openssl rand -hex 32`
- At least one model provider API key (e.g. `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`)

### 2. Start OpenClaw

```bash
docker compose up -d
```

### 3. Verify OpenClaw is Running

```bash
docker compose ps
```

Both services should show as "healthy".

### 4. Configure OpenClaw

The gateway generates a default config on first start. Run the setup wizard to choose a model
provider and set options:

```bash
docker compose exec openclaw-cli node dist/index.js configure
```

Or edit `openclaw.json` directly (it lives in the `openclaw_config` volume):

```bash
docker compose exec openclaw-gateway sh
vi /home/node/.openclaw/openclaw.json
```

Reload the gateway after changing the config:

```bash
docker compose exec openclaw-gateway node dist/index.js gateway reload
```

### 5. Access the Control UI

Open `http://localhost:18789` in your browser.

### 6. Stop OpenClaw

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have OpenClaw start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENCLAW_IMAGE` | ❌ | Image tag (default `ghcr.io/openclaw/openclaw:latest` when unset) |
| `OPENCLAW_GATEWAY_TOKEN` | ✅ | Authentication token for gateway access |
| `OPENCLAW_GATEWAY_BIND` | ❌ | Gateway bind address inside the container (`lan` or `localhost`, default `lan`) |
| `OPENCLAW_GATEWAY_PORT` | ❌ | Host port for the gateway (default `18789`) |
| `OPENCLAW_BRIDGE_PORT` | ❌ | Host port for the bridge service (default `18790`) |
| `OPENCLAW_MSTEAMS_PORT` | ❌ | Host port for Microsoft Teams (default `3978`) |
| `OPENCLAW_TZ` | ❌ | Timezone (default `UTC`) |
| `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GEMINI_API_KEY` / `OPENROUTER_API_KEY` | ⚠️ | Model provider keys — set at least one |
| `DOCKER_GID` | ❌ | Host docker group GID for sandbox support (SERVER only) |

All other options (channels, voice/media tools, OpenTelemetry, advanced flags) are passed
straight through from `.env` to the containers — see `.env.example` for the full list.

### Volumes

| Volume | Purpose |
|--------|---------|
| `openclaw_config` | OpenClaw configuration (`openclaw.json`) and state |
| `openclaw_workspace` | Agent workspace, skills, and tools |
| `openclaw_auth_secrets` | Authentication profile encryption keys |

### Ports

| Port | Purpose |
|------|---------|
| 18789 | Gateway API and Control UI |
| 18790 | Bridge service |
| 3978 | Microsoft Teams channel (optional) |

All ports are bound to `127.0.0.1` only by default. See the server checklist below before
exposing them publicly.

## Updating

1. Check the [OpenClaw releases](https://github.com/openclaw/openclaw/releases) page.
2. Bump `OPENCLAW_IMAGE` in `.env` to the next tag (e.g. `2026.7.1-2`).
3. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

## Migrating Existing Data

If you previously ran this stack with the host directories `~/.openclaw` and
`~/.openclaw-auth-profile-secrets` mounted in, copy the data into the named volumes once:

```bash
docker compose up -d  # ensure the volumes exist

docker run --rm -v openclaw_openclaw_config:/target -v "$HOME/.openclaw":/src \
  alpine sh -c "cp -a /src/. /target/"

docker run --rm -v openclaw_openclaw_auth_secrets:/target \
  -v "$HOME/.openclaw-auth-profile-secrets":/src \
  alpine sh -c "cp -a /src/. /target/"
```

Then restart and verify:

```bash
docker compose restart
docker compose exec openclaw-cli node dist/index.js gateway status
```

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `OPENCLAW_GATEWAY_TOKEN` (`openssl rand -hex 32`)
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Keep the gateway behind a reverse proxy (e.g. [Caddy](../caddy/), [Nginx](../nginx/),
      [Traefik](../traefik/)) with TLS instead of exposing ports directly
- [ ] Use bind mounts for `openclaw_config`, `openclaw_workspace`, and `openclaw_auth_secrets`
      for easier backups (see the `# SERVER:` comments in the volumes section)
- [ ] For sandbox isolation, mount the Docker socket, uncomment `group_add`, and set
      `DOCKER_GID` (`stat -c '%g' /var/run/docker.sock`)
- [ ] Back up the `openclaw_config`, `openclaw_workspace`, and `openclaw_auth_secrets` volumes —
      they hold all config, state, and credentials
- [ ] Read the upstream [Security Guide](https://docs.openclaw.ai/gateway/security)

## Supported Channels

OpenClaw supports many messaging platforms: WhatsApp, Telegram, Slack, Discord, Google Chat,
Signal, iMessage, IRC, Microsoft Teams, Matrix, Feishu, LINE, Mattermost, Nextcloud Talk,
Nostr, Synology Chat, Tlon, Twitch, Zalo, WeChat, QQ, and WebChat. Configure channel tokens in
`.env` and enable them in `openclaw.json`.

## Troubleshooting

### Gateway won't start

```bash
docker compose logs openclaw-gateway
```

Common issues:
- Missing `OPENCLAW_GATEWAY_TOKEN` (when binding beyond localhost)
- Invalid `openclaw.json` syntax
- Port conflicts (check if ports 18789, 18790 are already in use)

### Model provider errors

- Verify API keys are correct in `.env`
- Check provider status/outages
- Ensure network connectivity from the container

### Channel connection issues

- Verify channel tokens/bot credentials
- Check channel-specific documentation for setup requirements
- Review channel logs: `docker compose logs openclaw-gateway | grep -i <channel>`

### Sandbox issues

- Ensure the Docker socket is accessible
- Verify `DOCKER_GID` matches the host's docker group
- Check the container has the `docker` command available

## Useful Commands

```bash
# View all logs
docker compose logs -f

# View gateway logs only
docker compose logs -f openclaw-gateway

# Restart gateway
docker compose restart openclaw-gateway

# Gateway status
docker compose exec openclaw-cli node dist/index.js gateway status

# List active sessions
docker compose exec openclaw-cli node dist/index.js sessions list

# Reload configuration
docker compose exec openclaw-gateway node dist/index.js gateway reload

# Send a test message
docker compose exec openclaw-cli node dist/index.js message send --target <target> --message "Hello"

# Health check
curl -sf http://localhost:18789/healthz
```

## Resources

- [Official Documentation](https://docs.openclaw.ai/)
- [Getting Started Guide](https://docs.openclaw.ai/start/getting-started)
- [Configuration Reference](https://docs.openclaw.ai/gateway/configuration)
- [Channel Setup](https://docs.openclaw.ai/channels)
- [Security Guide](https://docs.openclaw.ai/gateway/security)
- [GitHub Repository](https://github.com/openclaw/openclaw)
