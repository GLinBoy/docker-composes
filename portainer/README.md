# Portainer

[Portainer](https://www.portainer.io/) is a lightweight management UI for Docker, Kubernetes, and
Swarm. This stack runs the official `portainer/portainer-ce` image and connects it to the local
Docker socket so you can manage the engine (and its containers, images, volumes, and networks) from
a web interface.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `portainer/portainer-ce:2.43.0-alpine` by default — bump `PORTAINER_IMAGE`
to update.

### 2. Start Portainer

```bash
docker compose up -d
```

### 3. Verify Portainer is Running

```bash
docker compose ps
```

The `portainer` service should show as "healthy".

### 4. Log In to Portainer

Open http://localhost:9000 in your browser. On first launch you will be prompted to create an admin
account.

### 5. Stop Portainer

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable              | Required | Description                                                  |
| --------------------- | -------- | ------------------------------------------------------------ |
| `PORTAINER_IMAGE`     | ❌       | Image tag (default `portainer/portainer-ce:2.43.0-alpine`)   |
| `PORTAINER_PORT`      | ❌       | Host port for the web UI (default `9000`, maps to 9000)      |
| `PORTAINER_HTTPS_PORT`| ❌       | Host port for HTTPS (default `9443`, commented out)          |
| `PORTAINER_EDGE_PORT` | ❌       | Host port for the Edge tunnel (default `8000`, commented out)|

### Volumes

| Volume                        | Purpose                          |
| ----------------------------- | -------------------------------- |
| `portainer_data:/data`        | Portainer database and settings  |

### Ports

| Port | Service            | Access                |
| ---- | ------------------ | --------------------- |
| 9000 | Portainer web UI   | localhost by default  |
| 9443 | Portainer HTTPS    | commented out         |
| 8000 | Edge tunnel        | commented out         |

## Production Considerations

### Before Deploying to Production:

1. **HTTPS**

   The web UI is served over plain HTTP on port 9000 by default. Uncomment the `9443` port mapping
   in `docker-compose.yml` to use HTTPS with the auto-generated self-signed certificate, or put
   Portainer behind a reverse proxy (see the [nginx-proxy-manager](../nginx-proxy-manager/),
   [Caddy](../caddy/), or [Traefik](../traefik/) stacks).

2. **Restart Policy**

   Uncomment the `restart: always` line in `docker-compose.yml` so Portainer comes back after a
   reboot or crash. Docker recommends this for the management UI.

3. **Bind Mount for Data**

   Uncomment the bind mount in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/portainer:/data
   ```

4. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs portainer
```

The healthcheck runs `wget` against the unauthenticated `/api/status` endpoint — an unhealthy
status usually means the container can't reach its own API, often because port 9000 is already in
use on the host.

### Port 9000 already in use

Change `PORTAINER_PORT` in `.env` and re-run `docker compose up -d`.

### Reset the data

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f portainer

# Back up the data volume
docker run --rm -v portainer_portainer_data:/data -v "$PWD":/backup alpine tar czf /backup/portainer_data.tar.gz -C /data .
```

## Resources

- [Portainer documentation](https://docs.portainer.io/)
- [Install Portainer CE with Docker](https://docs.portainer.io/start/install-ce/server/docker/linux)
- [Official portainer/portainer-ce image on Docker Hub](https://hub.docker.com/r/portainer/portainer-ce)
