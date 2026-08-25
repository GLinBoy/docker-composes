# Paperless-NGX

[Paperless-NGX](https://docs.paperless-ngx.com/) is a document management system that converts your
physical documents into a searchable online archive. It performs OCR, adds tags and searchable text,
and provides a web interface plus a REST API. This stack runs the official `paperlessngx/paperless-ngx`
image with PostgreSQL for storage and Redis as the message broker, using named volumes and a custom
network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Fill in the required values in `.env`:

- `POSTGRES_PASSWORD` — generate with `openssl rand -hex 32`
- `PAPERLESS_SECRET_KEY` — generate with `python3 -c "import secrets; print(secrets.token_urlsafe(64))"`
- Optionally adjust `USERMAP_UID` / `USERMAP_GID` to your user so you can write to the
  `consume/` directory

The images are pinned to `paperlessngx/paperless-ngx:3.0.5`, `redis:7.4.11-alpine`, and
`postgres:16.15-alpine` by default — bump `PAPERLESS_NGX_IMAGE`, `PAPERLESS_REDIS_IMAGE`, or
`PAPERLESS_POSTGRES_IMAGE` to update.

### 2. Prepare the Consume and Export Directories

Paperless watches `./consume` for new documents and writes exports to `./export`:

```bash
mkdir -p consume export
```

### 3. Start Paperless-NGX

```bash
docker compose up -d
```

### 4. Verify Paperless-NGX is Running

```bash
docker compose ps
```

All three services (`broker`, `db`, `webserver`) should show as "healthy". The webserver starts once
PostgreSQL and Redis are healthy.

### 5. Create the Superuser

```bash
docker compose exec webserver python3 manage.py createsuperuser
```

### 6. Access the Web UI

Open http://localhost:8000 in your browser and log in. The web UI will prompt you to add your first
document in the **consume** directory.

### 7. Stop Paperless-NGX

```bash
docker compose down
# Remove the named volumes too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                  | Required | Description                                                       |
| ------------------------- | -------- | ----------------------------------------------------------------- |
| `PAPERLESS_NGX_IMAGE`     | ❌       | App image tag (default `paperlessngx/paperless-ngx:3.0.5`)        |
| `PAPERLESS_REDIS_IMAGE`   | ❌       | Redis image (default `redis:7.4.11-alpine`)                       |
| `PAPERLESS_POSTGRES_IMAGE`| ❌       | PostgreSQL image (default `postgres:16.15-alpine`)                |
| `PAPERLESS_NGX_PORT`      | ❌       | Host port (default `8000`, maps to 8000)                          |
| `USERMAP_UID` / `USERMAP_GID` | ❌    | User/group to run paperless as (default `1000`)                   |
| `POSTGRES_DB`             | ❌       | Database name (default `paperless`)                               |
| `POSTGRES_USER`           | ❌       | Database user (default `paperless`)                               |
| `POSTGRES_PASSWORD`       | ✅       | Database password                                                 |
| `PAPERLESS_SECRET_KEY`    | ✅       | Session/signing secret key                                        |
| `PAPERLESS_URL`           | ❌       | Public URL of your instance (default `http://localhost:8000`)     |
| `PAPERLESS_TIME_ZONE`     | ❌       | Container timezone (default `UTC`)                                |
| `PAPERLESS_OCR_LANGUAGE`  | ❌       | Default OCR language (default `eng`)                              |

### Volumes

| Volume                         | Purpose                                   |
| ------------------------------ | ----------------------------------------- |
| `paperless_data:/usr/src/paperless/data` | SQLite-free data dir, search index |
| `paperless_media:/usr/src/paperless/media` | Original documents and thumbnails |
| `paperless_pgdata:/var/lib/postgresql/data` | PostgreSQL data                  |
| `paperless_redisdata:/data`    | Redis data                                |
| `./consume`                    | Drop documents here for ingestion         |
| `./export`                     | Exports are written here                  |

### Ports

| Port | Service                | Access               |
| ---- | ---------------------- | -------------------- |
| 8000 | Paperless-NGX web UI   | localhost by default |

## Production Considerations

### Before Deploying to Production:

1. **Set the Public URL and Allowed Hosts**

   In `.env`:

   ```bash
   PAPERLESS_URL=https://paperless.example.com
   ```

   `PAPERLESS_URL` sets `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`, and `CORS_ALLOWED_HOSTS`. If you use
   a dedicated reverse proxy subdomain, make sure this matches.

2. **Bind Mounts for Data**

   Uncomment the bind mounts in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/paperless-ngx/data:/usr/src/paperless/data
     - /data/paperless-ngx/media:/usr/src/paperless/media
     - /data/paperless-ngx/postgres:/var/lib/postgresql/data
     - /data/paperless-ngx/redis:/data
   ```

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` blocks in `docker-compose.yml`. OCR is
   CPU-intensive — budget accordingly.

4. **HTTPS**

   Put paperless-ngx behind a reverse proxy (see the [nginx-proxy-manager](../nginx-proxy-manager/),
   [Caddy](../caddy/), or [Traefik](../traefik/) stacks) and set `PAPERLESS_URL` to the HTTPS URL.

5. **Restart Policy**

   Uncomment `restart: unless-stopped` in `docker-compose.yml` so the containers come back after a
   host reboot or crash.

## Troubleshooting

### Container is unhealthy

```bash
docker compose ps
docker compose logs webserver
```

### Not creating the superuser

```bash
docker compose exec webserver python3 manage.py createsuperuser
```

### Documents not being consumed

Drop files into `./consume` (on the host) and wait — paperless watches it continuously. Check the
logs if nothing happens:

```bash
docker compose logs -f webserver
```

### Reset the data

Remove the named volumes and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f webserver

# Open a shell in the webserver container
docker compose exec webserver bash

# Back up the PostgreSQL database
docker compose exec db pg_dump -U paperless paperless > paperless_backup.sql

# Back up the data/media volumes
docker run --rm -v paperless-ngx_paperless_data:/data -v "$PWD":/backup alpine tar czf /backup/paperless_data.tar.gz -C /data .
docker run --rm -v paperless-ngx_paperless_media:/data -v "$PWD":/backup alpine tar czf /backup/paperless_media.tar.gz -C /data .
```

## Resources

- [Paperless-NGX documentation](https://docs.paperless-ngx.com/)
- [Configuration reference](https://docs.paperless-ngx.com/configuration/)
- [Official paperlessngx/paperless-ngx image on Docker Hub](https://hub.docker.com/r/paperlessngx/paperless-ngx)
