# Vaultwarden

[Vaultwarden](https://github.com/dani-garcia/vaultwarden) is an unofficial, lightweight
Rust implementation of the Bitwarden server API — fully compatible with all official Bitwarden
clients, at a fraction of the resource cost. This stack runs the official
[vaultwarden/server image](https://hub.docker.com/r/vaultwarden/server) (Debian-based; a smaller
`-alpine` variant is available) with a bind mount for its SQLite data directory.

The compose healthcheck reuses the image's built-in `/healthcheck.sh` script, which probes the
unauthenticated `/alive` endpoint with `curl`.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Then set in `.env`:

- `ADMIN_TOKEN` — token for the `/admin` panel, e.g. `openssl rand -hex 32` (leave empty to
  disable the panel entirely).
- `VAULTWARDEN_DOMAIN` — the public URL of this instance (e.g. `https://vault.example.com`). It is
  embedded in emails and WebAuthn flows, so it must match how you actually reach the server.
- SMTP settings — only needed for invites / password-reset mails: **uncomment the SMTP block in
  `docker-compose.yml`** and fill the values here; leave it alone to keep mail disabled.

The image is pinned to `vaultwarden/server:1.37.1` by default.

### 2. Start Vaultwarden

```bash
docker compose up -d
```

### 3. Verify Vaultwarden is Running

```bash
docker compose ps
```

The `vaultwarden` service should show as "healthy", and the Web vault should be up at
`http://localhost:8080/`.

### 4. Create Your Account

`SIGNUPS_ALLOWED=false` in `docker-compose.yml` blocks open registration, so onboard users one of
these ways:

- **Admin panel** — open `http://localhost:8080/admin`, authenticate with `ADMIN_TOKEN`, and
  invite users by email (requires SMTP).
- **Temporary open signups** — set `SIGNUPS_ALLOWED=true`, register, flip it back and
  `docker compose up -d`.

### 5. Stop the Stack

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Vaultwarden start automatically, add `restart: unless-stopped` to the service.

## Data & Configuration

| Mount         | Purpose                                                            |
| ------------- | ------------------------------------------------------------------ |
| `./data:/data`| SQLite DB (`db.sqlite3`), attachments, sends, RSA keys, icon cache |

| Host port (env)                    | Container | Purpose       |
| ---------------------------------- | --------- | ------------- |
| `VAULTWARDEN_PORT` (8080)          | 80        | Web vault/API |

### Environment Variables

| Variable             | Required | Description                                               |
| -------------------- | -------- | --------------------------------------------------------- |
| `VAULTWARDEN_VERSION`| ❌       | Image tag (default `1.37.1`)                              |
| `VAULTWARDEN_PORT`   | ❌       | Host port (default `8080`, maps to 80)                    |
| `VAULTWARDEN_DOMAIN` | ❌       | Public URL used in emails/links (empty = `localhost`)     |
| `ADMIN_TOKEN`        | ❌       | `/admin` panel token (empty = panel disabled)             |
| `SMTP_*`             | ❌       | Mail settings (uncomment SMTP block in compose first) |
| `TZ`                 | ❌       | Container timezone (default `UTC`)                        |

All other tuning (rate limits, `SIGNUPS_*`, feature flags) lives directly in
`docker-compose.yml`. Every Vaultwarden option is documented in the upstream
[.env.template](https://github.com/dani-garcia/vaultwarden/blob/main/.env.template).

## Updating

1. Back up `./data` (see [Production Considerations](#production-considerations)).
2. Bump `VAULTWARDEN_VERSION` in `.env` to the next release.
3. Pull and recreate — DB migrations run automatically on startup:

```bash
## Production Considerations

### 1. HTTPS Is Mandatory for Clients

Bitwarden clients refuse to connect over plain HTTP (except `localhost`). The typical setup is a
reverse proxy terminating TLS — [Traefik](../traefik/), [Caddy](../caddy/) or
[Nginx Proxy Manager](../nginx-proxy-manager/) — with `VAULTWARDEN_DOMAIN` set to the public
`https://` URL. When proxied, consider unpublishing the port and reaching Vaultwarden only through
the proxy network.

### 2. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Vaultwarden starts automatically on
boot or failure — a password manager is a service you want always up.

### 3. Protect the Admin Panel

- `ADMIN_TOKEN` in `.env` is stored in plain text. Vaultwarden accepts an **argon2 PHC string**
  instead — generate it once and put the whole `argon2:$argon2id$...` value into `.env`:

```bash
docker compose exec vaultwarden /vaultwarden hash
```

- If you don't need the panel at all, leave `ADMIN_TOKEN` empty (it stays disabled).
- The panel is rate-limited (`ADMIN_RATELIMIT_*`) but still — do not expose it publicly.

### 4. Backup the Data Directory

`./data` holds everything: the encrypted vault database (`db.sqlite3`), attachments, sends and the
RSA key pair. Back it up regularly; for a consistent snapshot, stop the stack first
(`docker compose stop`) and copy the directory, then start again.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. Vaultwarden is extremely
light — 512M is generous; the whole stack idles well below 100M.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs vaultwarden
```

The healthcheck needs a `200` from `/alive`. Failures usually mean the server failed to start —
common causes are a bad `config.json` override in `./data` or an unwritable data directory.

### Can't register an account

`SIGNUPS_ALLOWED=false` is intentional (see step 4 of Quick Start). Use an admin invite or
temporarily allow signups.

### Admin panel returns 404

`ADMIN_TOKEN` is empty — the panel is disabled. Set a token and `docker compose up -d`.

### Emails are not sent

SMTP settings are empty or wrong: check `SMTP_HOST` / `SMTP_FROM` / credentials in `.env`, and set
`VAULTWARDEN_DOMAIN` so links point to the right host. Port `587` implies STARTTLS.

### Port already in use

Change `VAULTWARDEN_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f vaultwarden

# Shell access
docker compose exec vaultwarden /bin/sh

# Generate an argon2 admin token (interactive)
docker compose exec vaultwarden /vaultwarden hash

# Check the liveness endpoint directly
curl -s http://localhost:8080/alive
```

## Resources

- [Vaultwarden GitHub](https://github.com/dani-garcia/vaultwarden)
- [Vaultwarden wiki (deployment & config)](https://github.com/dani-garcia/vaultwarden/wiki)
- [vaultwarden/server on Docker Hub](https://hub.docker.com/r/vaultwarden/server)
- [Bitwarden clients](https://bitwarden.com/download/)