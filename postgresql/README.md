# PostgreSQL

[PostgreSQL](https://www.postgresql.org/) is a powerful, open-source object-relational database
system. This stack runs the official `postgres` image (Alpine variant) with a named volume and a
custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set `POSTGRES_PASSWORD` to a strong password. The image is pinned to
`postgres:18.4-alpine3.23` by default — bump `POSTGRES_IMAGE` to update.

### 2. Start PostgreSQL

```bash
docker compose up -d
```

### 3. Verify PostgreSQL is Running

```bash
docker compose ps
```

The `postgresql` service should show as "healthy".

### 4. Connect to the Database

```bash
psql -h localhost -U postgres
```

Password: the value of `POSTGRES_PASSWORD` in your `.env`.

### 5. Stop PostgreSQL

```bash
docker compose down
# Remove the named volume too (deletes all data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable            | Required | Description                                              |
| ------------------- | -------- | -------------------------------------------------------- |
| `POSTGRES_IMAGE`    | ❌       | Image tag (default `postgres:18.4-alpine3.23`)           |
| `POSTGRES_PASSWORD` | ✅       | Password for the superuser (generate with `openssl rand -hex 32`) |
| `POSTGRES_USER`     | ❌       | Superuser name (default `postgres`)                      |
| `POSTGRES_DB`       | ❌       | Default database (default `postgres`)                    |
| `POSTGRES_PORT`     | ❌       | Host port (default `5432`, maps to 5432)                 |
| `POSTGRES_TZ`       | ❌       | Container timezone (default `UTC`)                       |

### Volumes

| Volume                        | Purpose                   |
| ----------------------------- | ------------------------- |
| `postgresql_data:/var/lib/postgresql/data` | Database files |

### Ports

| Port | Service      | Access                |
| ---- | ------------ | --------------------- |
| 5432 | PostgreSQL   | localhost by default  |

## Production Considerations

### Before Deploying to Production:

1. **Set a Strong Password**

   In `.env`:

   ```bash
   POSTGRES_PASSWORD=openssl rand -hex 32
   ```

2. **Bind Mount for Data**

   Uncomment the bind mount in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/postgresql:/var/lib/postgresql/data
   ```

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

4. **Backups**

   Use `pg_dump` for logical backups:

   ```bash
   docker compose exec postgresql pg_dump -U postgres postgres > backup.sql
   ```

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs postgresql
```

The healthcheck runs `pg_isready` — an unhealthy status usually means the server hasn't finished
initializing, or `POSTGRES_PASSWORD` / `POSTGRES_USER` don't match an existing data volume.

### Port 5432 already in use

Change `POSTGRES_PORT` in `.env` and re-run `docker compose up -d`.

### Reset the data

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

> Note: this deletes the data volume. If you were using the old `./data` bind mount from a previous
> version of this stack, back it up before removing it.

## Useful Commands

```bash
# View logs
docker compose logs -f postgresql

# Open an interactive psql session
docker compose exec postgresql psql -U postgres

# Back up the data volume
docker run --rm -v postgresql_postgresql_data:/var/lib/postgresql/data -v "$PWD":/backup alpine tar czf /backup/postgresql_data.tar.gz -C /var/lib/postgresql/data .
```

## Resources

- [PostgreSQL documentation](https://www.postgresql.org/docs/)
- [Official postgres image on Docker Hub](https://hub.docker.com/_/postgres)
