# Nginx

[Nginx](https://nginx.org/) is a high-performance HTTP server and reverse proxy. This stack
runs the official [`nginx` image](https://hub.docker.com/_/nginx) (Alpine) to serve your
static site from `./html` with your own `nginx.conf` configuration.

The site content and the configuration live in this folder, so you can edit them locally and
restart Nginx to pick up changes.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the ports or image version. The image is pinned to
`nginx:1.31.3-alpine3.24` by default — bump `NGINX_VERSION` to update.

### 2. Add Your Site Content

Put your website files in `./html`. The included `index.html` is only a placeholder.

### 3. Start Nginx

```bash
docker compose up -d
```

### 4. Verify Nginx is Running

```bash
docker compose ps
```

The `nginx` service should show as "healthy".

### 5. Test the Web Server

```bash
curl -sf http://localhost/ | head
```

### 6. Stop Nginx

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have Nginx start automatically, add `restart: unless-stopped` to the
> service.

## Configuration

### Environment Variables

| Variable            | Required | Description                                                       |
| ------------------- | -------- | ----------------------------------------------------------------- |
| `NGINX_VERSION`     | ❌       | Image tag (default `nginx:latest` when unset)                     |
| `NGINX_HTTP_PORT`   | ❌       | Host port for HTTP (default `80`, mapped to container 80)         |
| `NGINX_HTTPS_PORT`  | ❌       | Host port for HTTPS (default `443`, mapped to container 443)      |

### Files

| File            | Purpose                                             |
| --------------- | --------------------------------------------------- |
| `nginx.conf`    | Main Nginx configuration (mounted read-only)        |
| `html/`         | Site root — files are served by Nginx               |

### Ports

| Port | Service | Access             |
| ---- | ------- | ------------------ |
| 80   | Nginx   | HTTP web server    |
| 443  | Nginx   | HTTPS web server   |

## HTTPS / TLS

The `nginx.conf` includes a commented-out HTTPS server block. To enable it:

1. Obtain a certificate (e.g. with [certbot](https://certbot.eff.org/)) and place the
   `fullchain.pem` / `privkey.pem` files where the container can read them.
2. Uncomment the `443 ssl` server block in `nginx.conf`, update the
   `ssl_certificate` / `ssl_certificate_key` paths and mount the certificates, for example:

```yaml
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./html:/usr/share/nginx/html:ro
      - ./certs:/etc/nginx/certs:ro
```

3. Restart the stack with `docker compose restart nginx`.

## Updating

1. Check the [nginx image tags](https://hub.docker.com/_/nginx/tags) for the latest Alpine
   release.
2. Bump `NGINX_VERSION` in `.env` (e.g. `1.32.0-alpine3.24`).
3. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Add `restart: unless-stopped` to the service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block in `docker-compose.yml`
- [ ] Put Nginx behind a firewall, or terminate TLS and use it as a reverse proxy deliberately
- [ ] Enable HTTPS (see above) when serving content over the internet
- [ ] Back up `./html` (site content) and `nginx.conf` (configuration)

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs nginx
```

The healthcheck requests `http://localhost/`; a failure usually means the config is invalid
or Nginx can't bind the port. Validate the config first:

```bash
docker compose exec nginx nginx -t
```

### Port 80 already in use

Change `NGINX_HTTP_PORT` in `.env` (and/or `NGINX_HTTPS_PORT`) and re-run
`docker compose up -d`.

### Config errors after editing nginx.conf

```bash
docker compose exec nginx nginx -t
docker compose restart nginx
```

## Useful Commands

```bash
# View logs
docker compose logs -f nginx

# Shell access
docker exec -it nginx /bin/sh

# Reload configuration without restarting
docker compose exec nginx nginx -s reload
```

## Resources

- [Nginx website](https://nginx.org/)
- [Nginx documentation](https://nginx.org/en/docs/)
- [nginx image on Docker Hub](https://hub.docker.com/_/nginx)
