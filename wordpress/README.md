# WordPress

[WordPress](https://wordpress.org/) is the most widely used content management system in the world.
This stack runs the official [wordpress image](https://hub.docker.com/_/wordpress) (**Apache**
variant — WordPress is served directly by Apache on port 80) against a **MariaDB** database using
the official [mariadb image](https://hub.docker.com/_/mariadb) (11.x line by default — MariaDB 11.4
is the LTS; 11.8 is the latest short-term release).

> **Why the Apache variant?** The `-fpm`/`-fpm-alpine` images are FastCGI-only — they do **not**
> serve HTTP, so the port `80:80` mapping in a compose file would be dead without an additional web
> server. The Apache variant bundles everything and serves WordPress out of the box.

The compose healthchecks probe MariaDB with its built-in `healthcheck.sh` and WordPress with `curl`
(the image ships it).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Then set in `.env`:

- `WORDPRESS_DB_PASSWORD` — app database password, e.g. `openssl rand -hex 32`.
- `MYSQL_ROOT_PASSWORD` — MariaDB root password, e.g. `openssl rand -hex 32`.

### 2. Start WordPress

```bash
docker compose up -d
```

### 3. Verify WordPress is Running

```bash
docker compose ps
```

Both `wordpress` and `wordpress-mariadb` should show as "healthy", and WordPress answers at
`http://localhost/`.

### 4. Complete the WordPress Installation

Open `http://localhost/` and follow the 5-minute install wizard (language → site title, admin
user → install). The DB connection details are already wired up via environment variables — you
won't be asked for them.

### 5. Stop the Stack

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have WordPress start automatically, add `restart: unless-stopped` to the services.

## Data & Configuration

| Volume      | Container path   | Purpose                              |
| ----------- | ---------------- | ------------------------------------ |
| `html_data` | `/var/www/html`  | WordPress files, themes, uploads     |
| `db_data`   | `/var/lib/mysql` | MariaDB data files                   |

| Host port (env)        | Container | Purpose      |
| ---------------------- | --------- | ------------ |
| `WORDPRESS_PORT` (80)  | 80        | Web UI / API |

### Environment Variables

| Variable               | Required | Description                                        |
| ---------------------- | -------- | -------------------------------------------------- |
| `WORDPRESS_IMAGE`      | ❌       | Image tag (default `wordpress:7.0.4-php8.3-apache`)|
| `MARIADB_IMAGE`        | ❌       | DB image (default `mariadb:11.8.8`)                |
| `WORDPRESS_PORT`       | ❌       | Host port (default `80`, maps to 80)               |
| `WORDPRESS_DB_NAME`    | ❌       | Database name (default `wordpress`)                |
| `WORDPRESS_DB_USER`    | ❌       | Database user (default `wordpress`)                |
| `WORDPRESS_DB_PASSWORD`| ✅       | App DB password — REQUIRED                         |
| `MYSQL_ROOT_PASSWORD`  | ✅       | MariaDB root password — REQUIRED                   |
| `TZ`                   | ❌       | Container timezone (default `UTC`)                 |

## Updating

1. Back up `html_data` and `db_data` (see [Production Considerations](#production-considerations)).
2. Bump `WORDPRESS_IMAGE` in `.env` to a newer release (latest at the time of writing is
   `7.1.0-php8.3-apache`; see [wordpress.org](https://wordpress.org/download/) for current).
3. Pull and recreate — the image copies its WordPress source into `html_data` only on first start:

```bash
docker compose pull
docker compose up -d
```

> Plugins/themes are stored in `html_data`, so they survive image updates — but always back up
> before bumping a major version.

## Production Considerations

### 1. HTTPS

Terminate TLS with a reverse proxy ([Traefik](../traefik/), [Caddy](../caddy/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) in front of WordPress and, once proxied, consider
unpublishing the port. Set `WP_HOME`/`WP_SITEURL` or use a plugin to make WordPress generate
`https://` links.

### 2. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so the stack comes back automatically
after a reboot.

### 3. Protect the Passwords

`WORDPRESS_DB_PASSWORD` / `MYSQL_ROOT_PASSWORD` in `.env` are stored in plain text — restrict the
file permissions (`chmod 600 .env`). Never reuse the root password in your app config
(WordPress connects with its dedicated `WORDPRESS_DB_USER`, not root).

### 4. Backup Everything

- `html_data` — WordPress core, plugins, themes, `wp-content/uploads`.
- `db_data` — the entire database (posts, settings, users).

For a consistent DB snapshot, stop the stack (`docker compose stop`), copy both volumes, then start
again. For easier daily backups, switch the volumes to bind mounts documented in
`docker-compose.yml`.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` blocks. WordPress + MariaDB are light — 512M per service
is a reasonable starting point; increase if you run heavy plugins or traffic.

## Troubleshooting

### "Error establishing a database connection"

Check the DB is healthy and the credentials match `.env`:

```bash
docker compose ps
docker compose logs db
```

Both services read the same `WORDPRESS_DB_*` values, so the usual cause is an empty/mismatched
password or MariaDB still initializing.

### Container stays unhealthy

```bash
docker compose logs wordpress
```

The healthcheck needs a successful response from `http://localhost/`. On slow hosts WordPress may
take a while — increase `start_period` if it flips to "unhealthy" before Apache is up.

### Plugins/uploads show permission errors

The `html_data` volume is owned by `www-data` after the first start. Don't chmod the volume to
777 — fix ownership from inside the container e.g.:

```bash
docker compose exec wordpress chown -R www-data:www-data /var/www/html
```

### Port already in use

Change `WORDPRESS_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f wordpress

# Shell access
docker compose exec wordpress /bin/bash

# Verify the web UI directly
curl -s http://localhost/
```

## Resources

- [WordPress website](https://wordpress.org/)
- [wordpress image on Docker Hub](https://hub.docker.com/_/wordpress)
- [mariadb image on Docker Hub](https://hub.docker.com/_/mariadb)
> before bumping a major version.