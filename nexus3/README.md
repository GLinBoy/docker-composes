# Nexus3

[Nexus Repository Manager 3](https://www.sonatype.com/products/sonatype-nexus-repository) (Nexus3)
is a repository manager that proxies, caches, and hosts software components for Maven, npm, Docker,
PyPI, and more. This stack runs the official `sonatype/nexus3` image (UBI minimal, runs as user
`nexus`) with a named volume for its data and a custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `sonatype/nexus3:3.95.0` by default — bump `NEXUS_IMAGE` to update. Change
`NEXUS_HTTP_PORT` / `NEXUS_DOCKER_PORT` if the defaults collide with other services.

### 2. Start Nexus3

```bash
docker compose up -d
```

### 3. Verify Nexus3 is Running

```bash
docker compose ps
```

The `nexus` service should show as "healthy". First boot is slow (Nexus initializes its data
directory), so allow up to the 90s start period before deciding it is stuck.

### 4. Access the Web UI

Open `http://localhost:8081` and log in:

- Username: `admin`
- Password: read the generated admin password from the container:

```bash
docker exec nexus3 cat /nexus-data/admin.password
```

> Sonatype changed the default password flow — the initial admin password is generated on first
> boot and stored at `/nexus-data/admin.password`.

### 5. Stop Nexus3

```bash
docker compose down
# Remove the named volume too (deletes all data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable            | Required | Description                                                            |
| ------------------- | -------- | ---------------------------------------------------------------------- |
| `NEXUS_IMAGE`       | ❌       | Image tag (default `sonatype/nexus3:3.95.0`)                            |
| `NEXUS_HTTP_PORT`   | ❌       | Host port for the web UI, mapped to container 8081 (default `8081`)     |
| `NEXUS_DOCKER_PORT` | ❌       | Host port for a Docker hosted repo, mapped to 8085 (default `8085`)     |
| `NEXUS_TZ`          | ❌       | Container timezone (default `UTC`)                                      |

> The container's `8081` and `8085` ports are fixed; the env vars only change the host side so they
> don't collide with other services.

### Volumes

| Volume                 | Purpose                              |
| ---------------------- | ------------------------------------ |
| `nexus_data:/nexus-data` | All Nexus blobs, DB, config, logs |

### Ports

| Port | Service | Access                                  |
| ---- | ------- | --------------------------------------- |
| 8081 | Nexus3  | Web UI and REST API (TCP)               |
| 8085 | Nexus3  | Docker hosted repository (TCP, optional)|

## Updating

Bump `NEXUS_IMAGE` in `.env` and recreate:

```bash
docker compose pull
docker compose up -d
```

Refer to Sonatype's [Nexus3 upgrade docs](https://help.sonatype.com/nexus/repository-manager-3/upgrades)
for data migration notes before jumping major versions.

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Nexus starts automatically on boot or
failure.

### 2. Bind Mount for Data

Uncomment the bind mount driver options in `docker-compose.yml` for simpler backups:

```yaml
volumes:
  nexus_data:
    driver_opts:
      type: none
      o: bind
      device: /data/nexus3
```

Back up `/nexus-data` regularly (`blobs/`, `db/`, `etc/`, `log/`) — it is your entire Nexus state.

### 3. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. Nexus is JVM-based and
memory-hungry — size it for the number of repositories and stored components.

### 4. Docker Registry Port

Only keep the `8085` mapping if you actually created a Docker hosted repository in Nexus. Otherwise
remove it to reduce the exposed surface.

### 5. Reverse Proxy

Put Nexus behind one of the reverse-proxy stacks ([Caddy](../caddy/), [Traefik](../traefik/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) for automatic TLS.

## Troubleshooting

### Container stays unhealthy on first boot

```bash
docker compose logs nexus
```

Nexus is slow to start the first time while it initializes `/nexus-data`. If `start_period` (90s) is
too short, raise it in `docker-compose.yml`.

### Forgotten the admin password

If the `/nexus-data/admin.password` file is gone (already changed), reset it via the
[security reset procedure](https://help.sonatype.com/nexus/repository-manager-3/security). The data
lives in the `nexus_data` volume — `docker compose exec nexus3 sh` to inspect it.

### Port 8081 already in use

Change `NEXUS_HTTP_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f nexus

# Shell access (runs as user nexus)
docker exec -it nexus3 sh

# Read the initial admin password
docker exec nexus3 cat /nexus-data/admin.password

# Check the REST status endpoint
curl -sf http://localhost:8081/service/rest/v1/status

# Backup the data volume
docker run --rm -v nexus3_nexus_data:/nexus-data -v "$PWD":/backup alpine tar czf /backup/nexus_data.tar.gz -C /nexus-data .
```

## Resources

- [Nexus Repository Manager website](https://www.sonatype.com/products/sonatype-nexus-repository)
- [sonatype/nexus3 image on Docker Hub](https://hub.docker.com/r/sonatype/nexus3)
- [Nexus Repository Manager 3 docs](https://help.sonatype.com/nexus/repository-manager-3)
