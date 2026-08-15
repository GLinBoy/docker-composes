# Beszel

[Beszel](https://beszel.dev/) is a simple, lightweight server monitoring hub with Docker stats,
historical data, and alerts. This stack runs the official `henrygd/beszel` image (the Hub) with a
named volume and a custom network. Agents that connect to it are deployed separately (e.g. on the
hosts being monitored).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port. The image is pinned to `henrygd/beszel:0.18.7` by
default — bump `BESZEL_IMAGE` to update.

### 2. Start Beszel

```bash
docker compose up -d
```

### 3. Verify Beszel is Running

```bash
docker compose ps
```

The `beszel` service should show as "healthy".

### 4. Create the Admin User

Open http://localhost:8090 in your browser. On first launch you will be prompted to create an admin
account.

### 5. Add a System

Click **Add System**, choose an agent (see [Agent Installation](https://beszel.dev/guide/agent-installation)),
and configure it on the target host. If the system flips to green, it's working.

### 6. Stop Beszel

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable          | Required | Description                                             |
| ----------------- | -------- | ------------------------------------------------------- |
| `BESZEL_IMAGE`    | ❌       | Image tag (default `henrygd/beszel:0.18.7`)             |
| `BESZEL_PORT`     | ❌       | Host port (default `8090`, maps to 8090)                |
| `BESZEL_TZ`       | ❌       | Container timezone (default `UTC`)                      |
| `BESZEL_APP_URL`  | ❌       | Public URL of the Hub (default `http://localhost:8090`) |

### Volumes

| Volume                | Purpose                    |
| --------------------- | -------------------------- |
| `beszel_data:/beszel_data` | Hub database and data |

### Ports

| Port | Service             | Access               |
| ---- | ------------------- | -------------------- |
| 8090 | Beszel web UI / API | localhost by default |

## Production Considerations

### Before Deploying to Production:

1. **Set the Public URL**

   In `.env`:

   ```bash
   BESZEL_APP_URL=https://beszel.example.com
   ```

   Needed for correct links in alerts/notifications and OAuth redirects.

2. **Bind Mount for Data**

   Uncomment the bind mount in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/beszel:/beszel_data
   ```

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

4. **HTTPS**

   Put the Hub behind a reverse proxy (see the
   [nginx-proxy-manager](../nginx-proxy-manager/), [Caddy](../caddy/), or [Traefik](../traefik/)
   stacks) and point `BESZEL_APP_URL` at the HTTPS URL.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs beszel
```

### Port 8090 already in use

Change `BESZEL_PORT` in `.env` and re-run `docker compose up -d`.

### Reset the data

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f beszel

# Back up the data volume
docker run --rm -v beszel_beszel_data:/data -v "$PWD":/backup alpine tar czf /backup/beszel_data.tar.gz -C /data .
```

## Resources

- [Beszel documentation](https://beszel.dev/guide/what-is-beszel)
- [Hub Installation](https://beszel.dev/guide/hub-installation)
- [Agent Installation](https://beszel.dev/guide/agent-installation)
- [Official henrygd/beszel image on Docker Hub](https://hub.docker.com/r/henrygd/beszel)
