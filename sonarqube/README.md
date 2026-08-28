# SonarQube

[SonarQube](https://www.sonarsource.com/products/sonarqube/) is a self-managed, automatic code
review tool that continuously inspects code quality and security. This stack runs the official
Community Edition image backed by a PostgreSQL database, with named volumes for SonarQube data and
a custom network.

## Prerequisites

SonarQube bundles its own search engine, which needs a higher virtual-memory map count on the host:

```bash
sudo sysctl -w vm.max_map_count=262144
```

Make this permanent by adding `vm.max_map_count=262144` to `/etc/sysctl.conf`.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set `SONAR_DB_PASSWORD` to a strong password. The images are pinned to
`sonarqube:26.8.0.126808-community` and `postgres:16.2-alpine3.19` by default — bump
`SONARQUBE_VERSION` / `POSTGRES_IMAGE` to update.

### 2. Start SonarQube

```bash
docker compose up -d
```

### 3. Verify SonarQube is Running

```bash
docker compose ps
```

Both services should show as "healthy". First boot is slow (SonarQube initializes its search engine
and schema), so allow up to the 120s start period before deciding it is stuck.

### 4. Access the Web UI

Open `http://localhost:9001` and log in with the default credentials:

- Username: `admin`
- Password: `admin`

> You will be prompted to change the default admin password on first login.

### 5. Stop SonarQube

```bash
docker compose down
# Remove the named volumes too (deletes all data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable              | Required | Description                                                              |
| --------------------- | -------- | ------------------------------------------------------------------------ |
| `SONARQUBE_VERSION`   | ❌       | SonarQube image tag (default `26.8.0.126808-community`)                   |
| `POSTGRES_IMAGE`      | ❌       | PostgreSQL image tag (default `postgres:16.2-alpine3.19`)                 |
| `SONAR_DB_NAME`       | ❌       | Database name (default `sonar`)                                           |
| `SONAR_DB_USER`       | ❌       | Database user (default `sonar`)                                           |
| `SONAR_DB_PASSWORD`   | ✅       | Database password (generate with `openssl rand -hex 32`)                  |
| `SONARQUBE_PORT`      | ❌       | Host port for the web UI, mapped to container 9000 (default `9001`)       |

### Volumes

| Volume                        | Purpose                                      |
| ----------------------------- | -------------------------------------------- |
| `sonarqube_data:/opt/sonarqube/data`       | Search index and embedded data |
| `sonarqube_extensions:/opt/sonarqube/extensions` | Plugins |
| `sonarqube_logs:/opt/sonarqube/logs`       | Application logs               |
| `sonarqube_temp:/opt/sonarqube/temp`       | Temporary files                |
| `postgresql_data:/var/lib/postgresql/data` | PostgreSQL data files          |

### Ports

| Port | Service    | Access                     |
| ---- | ---------- | -------------------------- |
| 9001 | SonarQube  | Web UI (maps to container 9000) |

## Updating

Bump `SONARQUBE_VERSION` / `POSTGRES_IMAGE` in `.env` and recreate:

```bash
docker compose pull
docker compose up -d
```

Refer to SonarQube's [upgrade guide](https://docs.sonarsource.com/sonarqube/latest/setup-and-upgrade/upgrading-the-server/)
for database upgrade notes before jumping major versions.

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so SonarQube starts automatically on
boot or failure.

### 2. Bind Mounts for Data

Uncomment the bind mount driver options in `docker-compose.yml` for simpler backups. Back up the
`sonarqube_*` volumes and the PostgreSQL volume regularly.

### 3. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. SonarQube is
memory-hungry — the official recommendation is at least 2 GB of RAM for the application.

### 4. Reverse Proxy

Put SonarQube behind one of the reverse-proxy stacks ([Caddy](../caddy/), [Traefik](../traefik/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) for automatic TLS.

## Troubleshooting

### Container stays unhealthy on first boot

```bash
docker compose logs sonarqube
```

First boot is slow while the search engine and schema initialize. If `start_period` (120s) is too
short, raise it in `docker-compose.yml`.

### Elasticsearch exits with code 78

The host `vm.max_map_count` is too low — run the sysctl command from
[Prerequisites](#prerequisites).

### Postgres unhealthy

```bash
docker compose logs db
```

The healthcheck runs `pg_isready` — an unhealthy status usually means the server hasn't finished
initializing, or the password in `.env` doesn't match an existing data volume.

### Port 9001 already in use

Change `SONARQUBE_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f sonarqube

# Shell access
docker exec -it sonarqube bash

# SonarQube system status via API
curl -s http://localhost:9001/api/system/status

# Connect to the database
docker compose exec db psql -U sonar -d sonar
```

## Resources

- [SonarQube website](https://www.sonarsource.com/products/sonarqube/)
- [SonarQube Docker image on Docker Hub](https://hub.docker.com/_/sonarqube)
- [SonarQube server setup docs](https://docs.sonarsource.com/sonarqube/latest/setup-and-upgrade/)
