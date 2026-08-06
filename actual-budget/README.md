# Actual Budget

[Actual Budget](https://actualbudget.org) is a super-fast, privacy-focused, open-source budget
app. All your data lives on your own hardware — there is no cloud, no account, and no telemetry.
It tracks budgets, accounts, transactions, and schedules, and the mobile/desktop apps sync to
your own server.

This stack runs the Actual sync server, which stores all budget files in a single volume
(`server-files` and `user-files` subfolders under `/data`).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `ACTUAL_VERSION` - the exact Actual Budget version to run (defaults to `latest` when unset)
- `ACTUAL_PORT` - the host port for the web UI (default `5006`)

Optionally change:

- `ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB` - max sync file size in MB (default `20`)
- `TZ` - the container timezone (default `UTC`)

### 2. Start Actual Budget

```bash
docker compose up -d
```

### 3. Verify Actual Budget is Running

```bash
docker compose ps
```

The service should show as "healthy".

### 4. Create Your Server Password

Open http://localhost:5006 and follow the first-run setup to create the server password and your
first budget file.

### 5. View Logs

```bash
docker compose logs -f actual
```

### 6. Stop Actual Budget

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have Actual Budget start automatically, add `restart: unless-stopped` to the
> service.

## Configuration

### Environment Variables

| Variable                                | Required | Description                                            |
| --------------------------------------- | -------- | ------------------------------------------------------ |
| `ACTUAL_VERSION`                        | ❌       | Exact Actual Budget version (defaults to `latest`)     |
| `ACTUAL_PORT`                           | ❌       | Host port for the web UI (default: `5006`)             |
| `ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB` | ❌       | Max sync file size in MB (default: `20`)               |
| `TZ`                                    | ❌       | Container timezone (default: `UTC`)                    |

All other server options (HTTPS, login method, upload limits, trusted proxies, ...) are
documented in the [official configuration reference](https://actualbudget.org/docs/config/).

### Volumes

| Volume        | Purpose                                            |
| ------------- | -------------------------------------------------- |
| `actual-data` | All budget data (`server-files` and `user-files`)  |

### Ports

| Port | Purpose           |
| ---- | ----------------- |
| 5006 | Actual web UI     |

## Updating

1. Bump `ACTUAL_VERSION` in `.env` to the next release (e.g. `26.9.0-alpine`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set `ACTUAL_VERSION` to the exact release you want to run
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 5006
- [ ] Back up the `actual-data` volume (or bind mount `/data/actual-budget`) — it contains every budget file
- [ ] Review the [official backup guide](https://actualbudget.org/docs/backup-restore/backup/) and [troubleshooting docs](https://actualbudget.org/docs/troubleshooting/server/)
