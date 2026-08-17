# Duplicati

[Duplicati](https://www.duplicati.com/) is a free, open-source backup client that securely stores
encrypted, incremental, compressed backups on cloud storage services and remote file servers —
including Amazon S3, Backblaze B2, Microsoft Azure, Google Drive, SSH/SFTP, WebDAV and many more.

This stack runs the [official Duplicati image](https://hub.docker.com/r/duplicati/duplicati) with a
config volume and host mounts for the backup source and destination.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `DUPLICATI_SOURCE_PATH` - the host directory you want to back up (mounted as `/source`)
- `DUPLICATI_BACKUP_PATH` - where backups are stored locally (mounted as `/backups`)
- `DUPLICATI_UID` / `DUPLICATI_GID` - your host user/group id (`id -u` / `id -g`) so the
  container can read/write your directories

Optionally change:

- `DUPLICATI_PORT` - the host port for the web UI (default `8200`)
- `DUPLICATI_VERSION` - the exact Duplicati version to run (defaults to `latest` when unset)
- `DUPLICATI_TZ` - the timezone (default `UTC`)
- `DUPLICATI_WEBSERVICE_PASSWORD` / `DUPLICATI_SETTINGS_ENCRYPTION_KEY` - optional security
  settings (see [Security](#security))

### 2. Start Duplicati

```bash
docker compose up -d
```

### 3. Verify Duplicati is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Open the Web UI

Open http://localhost:8200 and follow the initial setup wizard to create your first backup.

### 5. View Logs

```bash
docker compose logs -f duplicati
```

### 6. Stop Duplicati

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Duplicati start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable                            | Required | Description                                                     |
| ----------------------------------- | -------- | --------------------------------------------------------------- |
| `DUPLICATI_SOURCE_PATH`             | ✅       | Host directory to back up (mounted as `/source`)                |
| `DUPLICATI_BACKUP_PATH`             | ✅       | Host directory for local backups (mounted as `/backups`)        |
| `DUPLICATI_UID` / `DUPLICATI_GID`   | ✅       | User/group ID the container processes run as                    |
| `DUPLICATI_VERSION`                 | ❌       | Exact Duplicati version (defaults to `latest` when unset)       |
| `DUPLICATI_PORT`                    | ❌       | Host port for the web UI (default: `8200`)                      |
| `DUPLICATI_TZ`                      | ❌       | Timezone (default: `UTC`)                                       |
| `DUPLICATI_WEBSERVICE_PASSWORD`     | ❌       | Web UI login password (requires uncommenting in compose)        |
| `DUPLICATI_SETTINGS_ENCRYPTION_KEY` | ❌       | Config database encryption key (requires uncommenting in compose) |

### Volumes

| Volume                | Purpose                                            |
| --------------------- | -------------------------------------------------- |
| `duplicati-config`    | Duplicati configuration and databases (`/data`)    |
| `/source` (bind)      | Host directory being backed up                     |
| `/backups` (bind)     | Host directory where local backups are stored      |

> Note: the official image stores its configuration in `/data` and runs under the user defined by
> the `UID`/`GID` environment variables (this is not a LinuxServer.io image, so `PUID`/`PGID` and
> `/config` do not apply).

### Ports

| Port | Purpose              |
| ---- | -------------------- |
| 8200 | Duplicati web UI     |

## Security

Before exposing the web UI beyond your local machine:

- Set `DUPLICATI_WEBSERVICE_PASSWORD` and uncomment `DUPLICATI__WEBSERVICE_PASSWORD` in
  `docker-compose.yml` to require a password for the web UI.
- Set `DUPLICATI_SETTINGS_ENCRYPTION_KEY` and uncomment `SETTINGS_ENCRYPTION_KEY` in
  `docker-compose.yml` to encrypt the config database. Store this key somewhere safe — without it
  the configuration cannot be read.
- Never mount your home directory (`/home/youruser`) as `/source` — mount only the specific
  subdirectories you want backed up.

## Updating

1. Bump `DUPLICATI_VERSION` in `.env` to the next release (e.g. `2.3.0.4`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set `DUPLICATI_SOURCE_PATH` / `DUPLICATI_BACKUP_PATH` to real directories
- [ ] Set `DUPLICATI_UID` / `DUPLICATI_GID` to a dedicated service user, not `1000:1000`
- [ ] Set a web UI password (`DUPLICATI_WEBSERVICE_PASSWORD`)
- [ ] Set a config database encryption key (`DUPLICATI_SETTINGS_ENCRYPTION_KEY`) and back it up
- [ ] Add `restart: unless-stopped` to the service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 8200
- [ ] Test restoring from a backup before relying on it
