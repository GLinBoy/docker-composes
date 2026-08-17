# DokuWiki

[DokuWiki](https://www.dokuwiki.org/) is a simple to use and highly versatile Open Source wiki
software that doesn't require a database. It stores all data in plain text files, which makes it
lightweight and easy to back up.

This stack runs the [official DokuWiki Docker image](https://hub.docker.com/r/dokuwiki/dokuwiki),
which is based on the official PHP Apache image and is meant to be used behind a reverse proxy
that handles SSL termination and authentication.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image manages its own user: it runs as root on startup to set up the `/storage` volume
(chowning it to `www-data`) and then drops privileges for Apache. No `PUID`/`PGID` setup is
needed for the named volume.

Optionally change:

- `DOKUWIKI_PORT` - the host port for the web UI (default `8080`)
- `DOKUWIKI_VERSION` - the exact DokuWiki version to run (defaults to `latest` when unset)
- `DOKUWIKI_TZ` - the timezone (default `UTC`)
- `PHP_MEMORYLIMIT` / `PHP_UPLOADLIMIT` - PHP process memory and upload size limits

### 2. Start DokuWiki

```bash
docker compose up -d
```

### 3. Verify DokuWiki is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Set Up the Wiki

Open http://localhost:8080 and follow the DokuWiki [installer](https://www.dokuwiki.org/installer)
to configure the wiki (admin user, ACL policy, etc.). The installer must be completed on the first
start.

### 5. View Logs

```bash
docker compose logs -f dokuwiki
```

### 6. Stop DokuWiki

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have DokuWiki start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable            | Required | Description                                                        |
| ------------------- | -------- | ------------------------------------------------------------------ |
| `DOKUWIKI_VERSION`  | ❌       | Exact DokuWiki version (defaults to `latest` when unset)           |
| `DOKUWIKI_PORT`     | ❌       | Host port for the web UI (default: `8080`)                         |
| `DOKUWIKI_TZ`       | ❌       | Timezone (default: `UTC`)                                          |
| `PHP_MEMORYLIMIT`   | ❌       | PHP process memory limit (default: `256M`)                         |
| `PHP_UPLOADLIMIT`   | ❌       | PHP upload size limit (default: `128M`)                            |

### Volumes

| Volume              | Purpose                                                          |
| ------------------- | ---------------------------------------------------------------- |
| `dokuwiki-storage`  | All wiki data: pages, media, plugins, templates, local config    |

### Ports

| Port | Purpose        |
| ---- | -------------- |
| 8080 | DokuWiki web UI |

## Updating

1. Bump `DOKUWIKI_VERSION` in `.env` to the next release (e.g. `2026-07-14a`). Available tags:
   `stable`, `oldstable`, `master`, or release dates.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

Bundled plugins and templates are kept in the container and symlinked into the storage volume, so
your local configuration and user data are preserved across updates.

## Server Checklist

Before deploying to a production server:

- [ ] Add `restart: unless-stopped` to the service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 8080
  — the image is designed to run behind a reverse proxy
- [ ] The image does not include a mail server — configure the [SMTP plugin](https://www.dokuwiki.org/plugin:smtp) to send emails
- [ ] Back up the `dokuwiki-storage` volume (all wiki data is stored there, no database to dump)
