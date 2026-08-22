# MariaDB

[MariaDB](https://mariadb.org/) is a community-developed, drop-in replacement for MySQL. It
is a relational database management system used by countless applications and supported by
all major programming languages.

This stack runs a single MariaDB server with a persistent data volume, ready to be used by
other services in your stack or connected to from the host.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `MARIADB_ROOT_PASSWORD` - generate with `openssl rand -hex 32`
- `MARIADB_PASSWORD` - generate with `openssl rand -hex 32`

Optionally change:

- `MARIADB_DATABASE` / `MARIADB_USER` - database name and user created on first start
- `MARIADB_PORT` - the host port for MariaDB (default `3306`)
- `MARIADB_IMAGE` - the exact MariaDB image to run

> Change the passwords BEFORE first start. If you change them after MariaDB has already
> initialized the data volume, the credentials stored in the database will no longer match.

### 2. Start MariaDB

```bash
docker compose up -d
```

### 3. Verify MariaDB is Running

```bash
docker compose ps
```

The service should show as "healthy".

### 4. Connect to MariaDB

From the host (any MySQL-compatible client):

```bash
mysql -h 127.0.0.1 -P 3306 -u mariadb -p
```

### 5. View Logs

```bash
docker compose logs -f mariadb
```

### 6. Stop MariaDB

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have MariaDB start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable                | Required | Description                                                     |
| ----------------------- | -------- | --------------------------------------------------------------- |
| `MARIADB_ROOT_PASSWORD` | ✅       | Root password for the MariaDB server                            |
| `MARIADB_PASSWORD`      | ✅       | Password for `MARIADB_USER`                                     |
| `MARIADB_IMAGE`         | ❌       | MariaDB image (exact-pinned, default: `mariadb:12.3.2`)         |
| `MARIADB_DATABASE`      | ❌       | Database created on first start (default: `mariadb`)            |
| `MARIADB_USER`          | ❌       | Application database user (default: `mariadb`)                  |
| `MARIADB_PORT`          | ❌       | Host port for MariaDB (default: `3306`)                         |
| `TZ`                    | ❌       | Timezone (default: `Etc/UTC`)                                   |

### Volumes

| Volume         | Purpose                |
| -------------- | ---------------------- |
| `mariadb_data` | MariaDB database files |

### Ports

| Port | Purpose               |
| ---- | --------------------- |
| 3306 | MySQL/MariaDB client  |

## Connecting from Another Container

Services in the same Docker network can reach MariaDB using the service name `mariadb`:

```yaml
services:
  myapp:
    networks:
      - mariadb-network
    environment:
      DB_HOST: mariadb
      DB_PORT: 3306
```

## Updating

1. Bump `MARIADB_IMAGE` in `.env` to the next release (e.g. `12.4.0`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set strong `MARIADB_ROOT_PASSWORD` and `MARIADB_PASSWORD` in `.env`
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Do not expose port 3306 to the public internet
- [ ] Review the [backup guide](https://mariadb.com/kb/en/backup-and-restore-overview/) for `mariadb_data`
