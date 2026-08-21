# LAMP

[LAMP](https://en.wikipedia.org/wiki/LAMP_(software_bundle)) is a classic web development
stack combining Linux, Apache, MySQL, and PHP. This stack runs a PHP + Apache web server
(built from a local Dockerfile with the `pdo_mysql` extension), a MySQL 8 database, and
Adminer for managing the database through a web UI.

It is designed for local web development: drop your PHP project files into `./src` and
they are served immediately by Apache.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `MYSQL_ROOT_PASSWORD` - generate with `openssl rand -hex 32`
- `MYSQL_PASSWORD` - generate with `openssl rand -hex 32`

Optionally change:

- `WEB_PORT` - the host port for Apache (default `8080`)
- `ADMINER_PORT` - the host port for Adminer (default `8081`)
- `MYSQL_PORT` - the host port for MySQL (default `3306`)
- `LAMP_PHP_IMAGE` - the base PHP/Apache image used by the Dockerfile build

> Change the passwords BEFORE first start. If you change them after MySQL has already
> initialized its data volume, the credentials stored in the database will no longer match.

### 2. Add Your PHP Project

Place your PHP project files in `./src`. A sample `src/index.php` (PHP info page) is
included so you can verify the stack works immediately.

### 3. Start LAMP

```bash
docker compose up -d --build
```

The `--build` flag is needed on first start (and after changing the Dockerfile) to
compile the PHP/Apache image.

### 4. Verify LAMP is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 5. Access the Services

- Web server (Apache + PHP): http://localhost:8080
- Adminer (database UI): http://localhost:8081

In Adminer, use the following to log in:

- Server: `mysql`
- User: `devuser` (or `root`)
- Password: the value of `MYSQL_PASSWORD` (or `MYSQL_ROOT_PASSWORD` for root)
- Database: `example`

### 6. View Logs

```bash
docker compose logs -f web
```

### 7. Stop LAMP

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have LAMP start automatically, add `restart: unless-stopped` to each
> service.

## Connecting to MySQL

From the web container:

```bash
docker compose exec web bash
mysql -h mysql -u devuser -p
```

From the host (any MySQL client):

```bash
mysql -h 127.0.0.1 -P 3306 -u devuser -p
```

## Configuration

### Environment Variables

| Variable               | Required | Description                                                         |
| ---------------------- | -------- | ------------------------------------------------------------------- |
| `MYSQL_ROOT_PASSWORD`  | ✅       | Root password for the MySQL server                                  |
| `MYSQL_PASSWORD`       | ✅       | Password for `MYSQL_USER`                                           |
| `LAMP_WEB_IMAGE`       | ❌       | Tag for the locally-built PHP/Apache image (default: `lamp-web:latest`) |
| `LAMP_PHP_IMAGE`       | ❌       | Base PHP/Apache image for the Dockerfile (default: `php:7.3-apache`) |
| `LAMP_MYSQL_IMAGE`     | ❌       | MySQL image (exact-pinned, default: `mysql:8.1.0`)                  |
| `LAMP_ADMINER_IMAGE`   | ❌       | Adminer image (exact-pinned, default: `adminer:4.7.5`)              |
| `WEB_PORT`             | ❌       | Host port for Apache (default: `8080`)                              |
| `MYSQL_PORT`           | ❌       | Host port for MySQL (default: `3306`)                               |
| `ADMINER_PORT`         | ❌       | Host port for Adminer (default: `8081`)                             |
| `MYSQL_DATABASE`       | ❌       | Database created on first start (default: `example`)                |
| `MYSQL_USER`           | ❌       | Application database user (default: `devuser`)                      |
| `TZ`                   | ❌       | Timezone (default: `Etc/UTC`)                                       |

### Volumes

| Volume       | Purpose                                      |
| ------------ | -------------------------------------------- |
| `./src`      | Your PHP project files (bind mount into Apache docroot) |
| `mysql_data` | MySQL database files (named volume)          |

### Ports

| Port | Purpose            |
| ---- | ------------------ |
| 8080 | Apache web server  |
| 8081 | Adminer web UI     |
| 3306 | MySQL server       |

## Adding PHP Extensions

The image is built from a local [Dockerfile](Dockerfile). To add extensions (e.g. `mysqli`,
`gd`, `xdebug`), edit the Dockerfile, rebuild, and recreate:

```bash
docker compose up -d --build web
```

## Updating

1. Bump the exact image values in `.env` as needed:
   - `LAMP_PHP_IMAGE` / `LAMP_MYSQL_IMAGE` / `LAMP_ADMINER_IMAGE`
2. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d --build
```

## Server Checklist

This stack targets local web development. Before deploying to a production server:

- [ ] Set strong `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` in `.env`
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) instead of exposing port 8080
- [ ] Do not expose MySQL port 3306 to the public internet
- [ ] Use the `php:apache` production image or build on a currently supported PHP version instead of `php:7.3-apache` (EOL)
- [ ] Review the [backup guide](https://dev.mysql.com/doc/refman/8.1/en/backup-and-recovery.html) for `mysql_data`
