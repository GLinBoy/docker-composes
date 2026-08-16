# BookStack

[BookStack](https://www.bookstackapp.com/) is a free, open-source Wiki designed for creating
beautiful documentation. It features a simple but powerful WYSIWYG editor and a Markdown editor
for those who prefer it, and stores everything in SQL.

This stack runs the BookStack web app (via the [LinuxServer.io](https://linuxserver.io) image)
and a MariaDB database.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `APP_KEY` - generate with `docker run -it --rm --entrypoint /bin/bash lscr.io/linuxserver/bookstack:latest appkey`
- `DB_PASSWORD` - alphanumeric password (must match the database)
- `DB_ROOT_PASSWORD` - alphanumeric MariaDB root password

Optionally change:

- `APP_URL` - the public URL of your installation
- `BOOKSTACK_PORT` - the host port for the web UI (default `6875`)
- `BOOKSTACK_VERSION` - the exact BookStack version to run (defaults to `latest` when unset)
- `DB_DATABASE` / `DB_USERNAME` - database name and user (defaults: `bookstackapp` / `bookstack`)

> Change the passwords BEFORE first start. If you change `DB_PASSWORD` after BookStack has
> already initialized the database, it will lose access.

### 2. Start BookStack

```bash
docker compose up -d
```

### 3. Verify BookStack is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Log In

Open http://localhost:6875 and log in with the default credentials `admin@admin.com` /
`password`. **Change them immediately** after first login.

### 5. View Logs

```bash
docker compose logs -f app
```

### 6. Stop BookStack

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have BookStack start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable                     | Required | Description                                                             |
| ---------------------------- | -------- | ----------------------------------------------------------------------- |
| `APP_KEY`                    | ✅       | Session encryption key (required — container halts without it)          |
| `DB_PASSWORD`                | ✅       | Database password (alphanumeric)                                        |
| `DB_ROOT_PASSWORD`           | ✅       | MariaDB root password (alphanumeric)                                    |
| `APP_URL`                    | ✅       | Public URL of the installation (used for links and CSRF)                |
| `BOOKSTACK_VERSION`          | ❌       | Exact BookStack version (defaults to `latest` when unset)               |
| `BOOKSTACK_DATABASE_IMAGE`   | ❌       | MariaDB image (exact-pinned)                                            |
| `BOOKSTACK_PORT`             | ❌       | Host port for the web UI (default: `6875`)                              |
| `DB_DATABASE`                | ❌       | Database name (default: `bookstackapp`)                                 |
| `DB_USERNAME`                | ❌       | Database user (default: `bookstack`)                                    |
| `QUEUE_CONNECTION`           | ❌       | Set to `database` to enable async actions (email, webhooks)             |
| `PUID` / `PGID`              | ❌       | User/group ID for the container processes (default: `1000`)             |
| `TZ`                         | ❌       | Timezone (default: `Etc/UTC`)                                           |

### Volumes

| Volume        | Purpose                                   |
| ------------- | ----------------------------------------- |
| `config_data` | BookStack config, uploads, themes, backups |
| `db_data`     | MariaDB database files                    |

### Ports

| Port | Purpose              |
| ---- | -------------------- |
| 6875 | BookStack web UI     |

## Updating

1. Bump `BOOKSTACK_VERSION` in `.env` to the next release (e.g. `26.06.0`).
2. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

3. BookStack runs database migrations on startup — allow it to finish before using the app.

## Server Checklist

Before deploying to a production server:

- [ ] Generate a strong `APP_KEY` and set it in `.env`
- [ ] Set strong `DB_PASSWORD` and `DB_ROOT_PASSWORD` (alphanumeric)
- [ ] Set `APP_URL` to your real public URL (required when behind a reverse proxy)
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 6875
- [ ] Review the [backup guide](https://www.bookstackapp.com/docs/admin/backup-restore/) for the database and `config_data`
- [ ] Optional: set `QUEUE_CONNECTION=database` to enable async actions like sending email or triggering webhooks

### Changing APP_URL After First Install

If you change `APP_URL` after the initial install, update the stored URLs:

```bash
docker exec -it bookstack-app php /app/www/artisan bookstack:update-url ${OLD_URL} ${NEW_URL}
```
