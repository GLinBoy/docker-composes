# Drupal

[Drupal](https://www.drupal.org/) is a free, open-source content management system used for
everything from personal blogs to large corporate and government sites.

This stack runs the [official Drupal FPM image](https://hub.docker.com/_/drupal) behind an
[Nginx](https://nginx.org/) web server, backed by a [MySQL](https://www.mysql.com/) database, with
a [Certbot](https://certbot.eff.org/) service for Let's Encrypt certificates.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `MYSQL_ROOT_PASSWORD` / `MYSQL_PASSWORD` - strong database passwords
- `CERTBOT_EMAIL` - your email address for Let's Encrypt (only needed when enabling TLS)
- `CERTBOT_DOMAIN` - your public domain (only needed when enabling TLS)

Optionally change:

- `DRUPAL_PORT` - the host port for the web UI (default `80`)
- `DRUPAL_VERSION` - the exact Drupal version to run (defaults to a stable fpm-alpine tag)
- `DRUPAL_TZ` - the timezone (default `UTC`)

### 2. Start Drupal

```bash
docker compose up -d
```

### 3. Verify Drupal is Running

```bash
docker compose ps
```

The `mysql`, `drupal`, and `webserver` services should show as "healthy". `certbot` runs once and
exits after issuing a (staging) certificate.

### 4. Set Up the Site

Open http://localhost and follow the Drupal installer to create your site. The database
connection settings are:

| Setting     | Value                         |
| ----------- | ----------------------------- |
| Database    | `MySQL` / `MariaDB`           |
| Host        | `mysql`                       |
| Database    | `drupal` (or your `MYSQL_DATABASE`) |
| User        | `drupal` (or your `MYSQL_USER`)     |
| Password    | the value of `MYSQL_PASSWORD` |

### 5. View Logs

```bash
docker compose logs -f drupal
```

### 6. Stop Drupal

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Drupal start automatically, add `restart: unless-stopped` to each service.

## Configuration

### Environment Variables

| Variable               | Required | Description                                                    |
| ---------------------- | -------- | -------------------------------------------------------------- |
| `MYSQL_ROOT_PASSWORD`  | ✅       | MySQL root password                                            |
| `MYSQL_PASSWORD`       | ✅       | MySQL application user password                                |
| `MYSQL_DATABASE`       | ❌       | Database name (default: `drupal`)                              |
| `MYSQL_USER`           | ❌       | MySQL application user (default: `drupal`)                     |
| `DRUPAL_VERSION`       | ❌       | Exact Drupal version (defaults to a stable fpm-alpine tag)     |
| `DRUPAL_PORT`          | ❌       | Host port for the web UI (default: `80`)                       |
| `DRUPAL_TZ`            | ❌       | Timezone (default: `UTC`)                                      |
| `MYSQL_IMAGE`          | ❌       | MySQL image (exact-pinned)                                     |
| `NGINX_IMAGE`          | ❌       | Nginx image (exact-pinned)                                     |
| `CERTBOT_IMAGE`        | ❌       | Certbot image (exact-pinned)                                   |
| `CERTBOT_EMAIL`        | ⚠️       | Email for Let's Encrypt (required when enabling TLS)           |
| `CERTBOT_DOMAIN`       | ⚠️       | Public domain for the certificate (default: `localhost`)       |
| `CERTBOT_STAGING_FLAG` | ❌       | `--staging` for test certs, empty for production               |

### Volumes

| Volume        | Purpose                                                    |
| ------------- | ---------------------------------------------------------- |
| `mysql-data`  | MySQL database files                                       |
| `drupal-data` | Drupal web root (`/opt/drupal/web`, shared with nginx)     |
| `certbot-data`| Let's Encrypt certificates and account data                |

The Nginx site configuration lives in the tracked file `data/nginx-data/nginx.conf` and is
mounted read-only into `/etc/nginx/conf.d/default.conf`.

### Ports

| Port | Purpose        |
| ---- | -------------- |
| 80   | Drupal web UI  |

## Enabling TLS with Certbot

By default the stack issues a **staging** certificate for `localhost` so the full flow works
without a real domain. To enable a production certificate:

1. Set `CERTBOT_DOMAIN` to your real domain and `CERTBOT_EMAIL` to your email in `.env`.
2. Set `CERTBOT_STAGING_FLAG` to empty (`CERTBOT_STAGING_FLAG=`).
3. Update `server_name` in `data/nginx-data/nginx.conf` to your domain.
4. Recreate the stack:

```bash
docker compose up -d
```

> Note: port 80 must be reachable from the internet for the HTTP-01 webroot challenge to work.
> The Nginx config currently only serves HTTP — extend it with a port 443 `server` block that
> references `/etc/letsencrypt/live/<your-domain>/fullchain.pem` and `privkey.pem` once the
> certificate exists, and add `443:443` to the `webserver` ports.

## Updating

1. Bump `DRUPAL_VERSION` in `.env` to the next release (e.g. `11.3.10-fpm-alpine3.23`).
2. Recreate the containers:

```bash
docker compose pull
docker compose up -d
```

3. Run Drupal's database update once the new container is up:
   [https://www.drupal.org/docs/updating-drupal/upgrading-from-a-previous-version](https://www.drupal.org/docs/updating-drupal/upgrading-from-a-previous-version)

## Server Checklist

Before deploying to a production server:

- [ ] Set strong `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` (e.g. `openssl rand -hex 32`)
- [ ] Set `CERTBOT_EMAIL`, `CERTBOT_DOMAIN`, and clear `CERTBOT_STAGING_FLAG`
- [ ] Update `server_name` in `data/nginx-data/nginx.conf` to your real domain
- [ ] Add a port 443 server block with the issued certificate paths, and expose `443:443`
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Back up `mysql-data` and `drupal-data` volumes (Drupal also allows exports via its admin UI)
