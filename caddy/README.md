# Caddy

[Caddy](https://caddyserver.com/) is a powerful, enterprise-ready, open source web server with
automatic HTTPS written in Go. It gets secure HTTPS for any domain by default and requires no
configuration to get certificates issued and renewed.

This stack runs the Caddy web server and reverse proxy, mounting your `Caddyfile` from
`./caddy-config` and persisting certificates and runtime state in named volumes.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum (only if you need automatic HTTPS in production):

- `CADDY_EMAIL` - your email for Let's Encrypt notifications
- `ACME_AGREE=true` - agree to the ACME Terms of Service

Optionally change:

- `CADDY_VERSION` - the exact Caddy version to run (defaults to `latest` when unset)
- `CADDY_HTTP_PORT` / `CADDY_HTTPS_PORT` - the host ports for HTTP/HTTPS (defaults: `80` / `443`)

### 2. Create a Caddyfile

Create `caddy-config/Caddyfile` to define your site configuration:

```caddyfile
# Example Caddyfile for local development
:80 {
    respond "Hello from Caddy!"
}
```

### 3. Start Caddy

```bash
docker compose up -d
```

### 4. Verify Caddy is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 5. Test Your Configuration

```bash
# Test HTTP response
curl http://localhost

# Check Caddy metrics (admin API)
curl http://localhost:2019/metrics
```

### 6. View Logs

```bash
docker compose logs -f caddy
```

### 7. Stop Caddy

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have Caddy start automatically, add `restart: unless-stopped` to the
> service.

## Configuration

### Environment Variables

| Variable            | Required | Description                                                            |
| ------------------- | -------- | ---------------------------------------------------------------------- |
| `CADDY_VERSION`     | ❌       | Exact Caddy version (defaults to `latest` when unset)                  |
| `CADDY_HTTP_PORT`   | ❌       | Host port for HTTP traffic (default: `80`)                             |
| `CADDY_HTTPS_PORT`  | ❌       | Host port for HTTPS traffic (default: `443`)                           |
| `CADDY_ADMIN`       | ❌       | Admin API address (default: `localhost:2019`)                          |
| `CADDY_GRACE_PERIOD`| ❌       | Grace period for graceful shutdown (default: `10s`)                    |
| `ACME_AGREE`        | ❌       | Set to `true` to agree to the ACME Terms of Service (default: `false`) |
| `ACME_CA`           | ❌       | Custom ACME CA URL (empty = Let's Encrypt)                             |
| `CADDY_EMAIL`       | ❌       | Email for Let's Encrypt notifications                                  |

### Caddyfile

The `Caddyfile` in `./caddy-config` is mounted read-only to `/etc/caddy/Caddyfile` inside the
container. After editing it, reload without downtime:

```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

Validate the syntax first:

```bash
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
```

Example Caddyfile for a reverse proxy with automatic HTTPS (production):

```caddyfile
example.com {
    reverse_proxy backend-service:8080
}
```

### Volumes

| Volume         | Purpose                                        |
| -------------- | ---------------------------------------------- |
| `./caddy-config` | Your Caddyfile (bind mount, read-only)       |
| `caddy_data`   | SSL certificates and site data                 |
| `caddy_config` | Caddy runtime configuration                    |

### Ports

| Port | Purpose                                          |
| ---- | ------------------------------------------------ |
| 80   | HTTP traffic                                     |
| 443  | HTTPS traffic (automatic with Caddy)             |
| 2019 | Caddy admin API (internal, used by the healthcheck) |

## Updating

1. Bump `CADDY_VERSION` in `.env` to the next release (e.g. `2.12.0-alpine`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set `CADDY_EMAIL` to your real email and `ACME_AGREE=true` in `.env`
- [ ] Ensure firewall rules allow ports 80 and 443 (Let's Encrypt needs inbound 80 to validate)
- [ ] Point your domain's DNS records at the server before enabling HTTPS
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Consider bind mounts for `caddy_data` / `caddy_config` for easier backup control
- [ ] Verify the certificate after startup: `curl -vI https://your-domain.com`

## Useful Commands

```bash
# View Caddy version
docker compose exec caddy caddy version
```

## Troubleshooting

### Caddy won't start

Check the logs:

```bash
docker compose logs caddy
```

### SSL certificates not issuing

- Ensure port 80 is reachable from the internet (Let's Encrypt validates through it)
- Check that DNS records point to your server
- Verify `ACME_AGREE=true` is set
- Test with a staging endpoint via `ACME_CA` before switching to the production CA

### Admin API not accessible

The admin API listens on `localhost:2019` inside the container. To access it from outside, map
the port in the `ports` section of `docker-compose.yml`.

## Resources

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Caddyfile Syntax](https://caddyserver.com/docs/caddyfile)
- [Caddy API](https://caddyserver.com/docs/api)
- [Automatic HTTPS](https://caddyserver.com/docs/automatic-https)
