# Firefly III

[Firefly III](https://www.firefly-iii.org/) is a self-hosted personal finance manager. It
lets you track expenses, budgets, savings, and recurring transactions from your own hardware,
with a REST API and a [data importer](https://docs.firefly-iii.org/how-to/data-importer/) for
bank statements.

This stack runs the Firefly III web app, a MariaDB database, and a small cron container that
triggers Firefly III's recurring transactions and bill reminders.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `APP_KEY` - random string of exactly 32 characters (`head /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 32 && echo`)
- `DB_PASSWORD` - alphanumeric password (must match the database)
- `DB_ROOT_PASSWORD` - alphanumeric MariaDB root password
- `STATIC_CRON_TOKEN` - random string of exactly 32 characters (same command as `APP_KEY`)

Optionally change:

- `APP_URL` - the public URL of your installation
- `FIREFLYIII_PORT` - the host port for the web UI (default `8080`)
- `FIREFLYIII_VERSION` - the exact Firefly III version to run (defaults to `latest` when unset)
- `DB_DATABASE` / `DB_USERNAME` - database name and user (defaults: `firefly`)

> Change the passwords BEFORE first start. If you change `DB_PASSWORD` after Firefly III has
> already initialized the database, it will lose access.

### 2. Start Firefly III

```bash
docker compose up -d
```

### 3. Verify Firefly III is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Create Your Account

Open http://localhost:8080 and follow the onboarding to create your admin account.

### 5. View Logs

```bash
docker compose logs -f app
```

### 6. Stop Firefly III

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have Firefly III start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable                   | Required | Description                                                             |
| -------------------------- | -------- | ----------------------------------------------------------------------- |
| `APP_KEY`                  | ✅       | App encryption key (exactly 32 chars, alphanumeric)                     |
| `DB_PASSWORD`              | ✅       | Database password (alphanumeric)                                        |
| `DB_ROOT_PASSWORD`         | ✅       | MariaDB root password (alphanumeric)                                    |
| `STATIC_CRON_TOKEN`        | ✅       | Cron token (exactly 32 chars, alphanumeric)                             |
| `APP_URL`                  | ✅       | Public URL of the installation                                          |
| `FIREFLYIII_VERSION`       | ❌       | Exact Firefly III version (defaults to `latest` when unset)             |
| `FIREFLYIII_DATABASE_IMAGE`| ❌       | MariaDB image (exact-pinned)                                            |
| `FIREFLYIII_CRON_IMAGE`    | ❌       | Cron base image (exact-pinned)                                          |
| `FIREFLYIII_PORT`          | ❌       | Host port for the web UI (default: `8080`)                              |
| `DB_DATABASE`              | ❌       | Database name (default: `firefly`)                                      |
| `DB_USERNAME`              | ❌       | Database user (default: `firefly`)                                      |
| `TZ`                       | ❌       | Timezone (default: `Etc/UTC`)                                           |
| `TRUSTED_PROXIES`          | ❌       | Proxies allowed to set `X-Forwarded-*` headers (default: `**`)          |

### Volumes

| Volume        | Purpose                                     |
| ------------- | ------------------------------------------- |
| `upload_data` | Uploaded files (e.g. attachments)           |
| `db_data`     | MariaDB database files                      |

### Ports

| Port | Purpose               |
| ---- | --------------------- |
| 8080 | Firefly III web UI    |

### Optional: PostgreSQL

Firefly III also supports PostgreSQL. To switch, change in `docker-compose.yml`:

- `DB_CONNECTION=mariadb` to `DB_CONNECTION=pgsql`, `DB_HOST=db`, `DB_PORT=5432`
- The `db` service image to `postgres` (e.g. `postgres:18-alpine`)
- The `db_data` volume mount point to `/var/lib/postgresql/data`
- The database env vars from `MARIADB_*` to `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB`

## Updating

1. Bump `FIREFLYIII_VERSION` in `.env` to the next release (e.g. `version-6.7.0`).
2. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

3. Firefly III may run one-time migrations on startup — allow it to finish before using the app.

## Server Checklist

Before deploying to a production server:

- [ ] Set a strong `APP_KEY`, `DB_PASSWORD`, `DB_ROOT_PASSWORD`, and `STATIC_CRON_TOKEN`
- [ ] Set `APP_URL` to your real public URL and restrict `TRUSTED_PROXIES` to your reverse proxy's IP
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 8080
- [ ] Review the [backup guide](https://docs.firefly-iii.org/how-to/firefly-iii/advanced/backup/) for the database and `upload_data`
- [ ] Optional: install the [Data Importer](https://docs.firefly-iii.org/how-to/data-importer/installation/docker/) to import bank statements
