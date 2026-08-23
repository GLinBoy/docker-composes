# MySQL

[MySQL](https://www.mysql.com/) is the world's most popular open-source relational database
management system. This stack runs the official `mysql` image with UTF-8 support, a named volume for
data persistence, and a custom network. It listens on port 3306 and creates a database and optional
application user on first start.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set a strong `MYSQL_ROOT_PASSWORD`. The image is pinned to `mysql:26.7.0` by
default — bump `MYSQL_IMAGE` to update.

### 2. Start MySQL

```bash
docker compose up -d
```

The first start initializes the data directory and can take 30–60 seconds. Subsequent starts are fast.

### 3. Verify MySQL is Running

```bash
docker compose ps
```

The `db` service should show as "healthy". The healthcheck uses `mysqladmin ping` with the root
password and fails when the server is down or unreachable.

### 4. Connect

```bash
# From the host (requires a MySQL client)
mysql -h 127.0.0.1 -P 3306 -uroot -p

# From inside the container
docker compose exec db mysql -uroot -p
```

### 5. Stop MySQL

```bash
docker compose down
# Remove the named volume too (deletes all data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable               | Required | Description                                                          |
| ---------------------- | -------- | -------------------------------------------------------------------- |
| `MYSQL_IMAGE`          | ❌       | Image tag (default `mysql:26.7.0`)                                   |
| `MYSQL_ROOT_PASSWORD`  | ✅       | Root password (no default — set a strong one)                        |
| `MYSQL_DATABASE`       | ❌       | Database created on first start (default `sandbox`)                  |
| `MYSQL_USER`           | ❌       | Application user created on first start (default none)               |
| `MYSQL_PASSWORD`       | ❌       | Password for `MYSQL_USER` (required if user is set)                  |
| `MYSQL_PORT`           | ❌       | Host port (default `3306`)                                           |
| `MYSQL_TZ`             | ❌       | Container timezone (default `UTC`)                                   |

### Volumes

| Volume                  | Purpose                      |
| ----------------------- | ---------------------------- |
| `mysql_data:/var/lib/mysql` | MySQL data directory (InnoDB tablespaces, system DB) |

### Ports

| Port | Service    | Access      |
| ---- | ---------- | ----------- |
| 3306 | MySQL      | localhost by default |

## Server Configuration

The server is started with:

- `--character-set-server=utf8mb4`
- `--collation-server=utf8mb4_unicode_ci`

This provides full UTF-8 support for all databases and connections.

## Production Considerations

### 1. Set a Strong Root Password

`MYSQL_ROOT_PASSWORD` has no default. Generate a strong one:

```bash
openssl rand -hex 32
```

### 2. Create a Dedicated Application User

The `MYSQL_USER` / `MYSQL_PASSWORD` pair creates an app user on first start with access to
`MYSQL_DATABASE`. Use this instead of root for your application. Note: `mysql_native_password` was
removed in MySQL 9+ — the default `caching_sha2_password` plugin is used, so use a current client
library.

### 3. Bind Mount for Data

Uncomment the bind mount in `docker-compose.yml` for easier backup control:

```yaml
volumes:
  - /data/mysql:/var/lib/mysql
```

The container runs as UID `999` (`mysql`). If you switch to a bind mount, ensure the host directory
is writable by that UID:

```bash
sudo chown -R 999:999 /data/mysql
```

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 5. Restart Policy

Containers stop when the host restarts (repo convention — no `restart:` policy is set). If you want
the database to survive reboots, add to the service:

```yaml
restart: unless-stopped
```

## Backups

### Logical dump (mysqldump)

```bash
docker compose exec db sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > backup.sql
```

### Restore

```bash
cat backup.sql | docker compose exec -T db sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"'
```

## Troubleshooting

### Container is unhealthy

Check the logs:

```bash
docker compose logs db
```

Common issues:

- First start is still initializing — the healthcheck has a 60s start period
- Port already in use — change `MYSQL_PORT` in `.env`
- Volume permissions (bind mounts only) — ensure the host dir is owned by UID `999`

### Reset the database

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f db

# Interactive shell inside the container
docker compose exec db bash

# Run a SQL query
docker compose exec db mysql -uroot -p -e "SHOW DATABASES;"

# Check server status
docker compose exec db mysqladmin status -uroot -p

# Stop the stack
docker compose down
```
