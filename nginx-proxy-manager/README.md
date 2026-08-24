# Nginx Proxy Manager

[Nginx Proxy Manager](https://nginxproxymanager.com/) is a pre-built Docker image that brings
you an easy way to reverse proxy your websites with free Let's Encrypt SSL certificates,
without needing to know much about Nginx. Manage proxies, redirections, streams, and SSL
certificates from a clean web UI.

This stack runs the official [`jc21/nginx-proxy-manager` image](https://hub.docker.com/r/jc21/nginx-proxy-manager)
backed by a PostgreSQL database.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `NPM_DB_PASSWORD` - database password, generate with `openssl rand -hex 24`

Optionally change:

- `NPM_ADMIN_PORT` - the host port for the admin UI (default `81`)
- `NPM_HTTP_PORT` / `NPM_HTTPS_PORT` - public HTTP/HTTPS ports (default `80` / `443`)
- `NPM_VERSION` - the exact image version to run (defaults to `latest` when unset)

### 2. Start Nginx Proxy Manager

```bash
docker compose up -d
```

### 3. Verify it is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Log In to the Admin UI

Open `http://localhost:81` and log in with the default credentials:

- Email: `admin@example.com`
- Password: `changeme`

> ⚠️ **Change the default admin password immediately after first login.**

### 5. Stop Nginx Proxy Manager

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have NPM start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable            | Required | Description                                                        |
| ------------------- | -------- | ------------------------------------------------------------------ |
| `NPM_VERSION`       | ❌       | Image version (default `jc21/nginx-proxy-manager:latest` when unset) |
| `NPM_DB_IMAGE`      | ❌       | PostgreSQL image (default `docker.io/postgres:17-alpine`)          |
| `TZ`                | ❌       | Timezone (default `Etc/UTC`)                                       |
| `NPM_ADMIN_PORT`    | ❌       | Host port for the admin UI (default `81`, container fixed to 81)   |
| `NPM_HTTP_PORT`     | ❌       | Host port for public HTTP (default `80`, container fixed to 80)    |
| `NPM_HTTPS_PORT`    | ❌       | Host port for public HTTPS (default `443`, container fixed to 443) |
| `NPM_DB_USER`       | ❌       | Database user (default `npm`)                                      |
| `NPM_DB_NAME`       | ❌       | Database name (default `npm`)                                      |
| `NPM_DB_PASSWORD`   | ✅       | Database password (`openssl rand -hex 24`)                         |

### Volumes

| Volume               | Purpose                                       |
| -------------------- | --------------------------------------------- |
| `npm_data`           | NPM application data (certificates, settings) |
| `npm_letsencrypt`    | Let's Encrypt certificates                    |
| `npm_postgres_data`  | PostgreSQL database files                     |

### Ports

| Port | Access                     |
| ---- | -------------------------- |
| 80   | Public HTTP (proxy traffic)|
| 443  | Public HTTPS (proxy traffic)|
| 81   | Admin web UI               |

## Updating

1. Check the [nginx-proxy-manager releases](https://github.com/NginxProxyManager/nginx-proxy-manager/releases)
   for the latest version.
2. Bump `NPM_VERSION` in `.env` (e.g. `2.16.0`).
3. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `NPM_DB_PASSWORD` in `.env` (`openssl rand -hex 24`)
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Change the default admin password (`admin@example.com` / `changeme`) after first login
- [ ] Keep ports 80/443 behind a firewall, or only expose them deliberately
- [ ] Back up the `npm_data`, `npm_letsencrypt`, and `npm_postgres_data` volumes

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs npm
```

The healthcheck requests `http://localhost:81/login`; a failure usually means the app is
still starting or the database connection failed.

### Default admin login doesn't work

Reset the admin user as described in the
[Nginx Proxy Manager documentation](https://nginxproxymanager.com/guide/).

## Useful Commands

```bash
# View logs
docker compose logs -f npm

# Shell access
docker exec -it npm /bin/sh
```

## Resources

- [Nginx Proxy Manager website](https://nginxproxymanager.com/)
- [Nginx Proxy Manager documentation](https://nginxproxymanager.com/guide/)
- [jc21/nginx-proxy-manager image on Docker Hub](https://hub.docker.com/r/jc21/nginx-proxy-manager)
