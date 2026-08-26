# Pulse

[Pulse](https://github.com/rcourtman/Pulse) is a self-hosted infrastructure monitoring workspace
for Proxmox, Docker, Kubernetes, TrueNAS, virtual/physical machines, and early-access VMware
vSphere. It combines live state, history, alerts, recovery visibility, and scheduled health checks.
This stack runs the official `rcourtman/pulse` image (Community build) with a named volume and a
custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `rcourtman/pulse:6.2.1` by default — bump `PULSE_IMAGE` to update.

### 2. Start Pulse

```bash
docker compose up -d
```

### 3. Verify Pulse is Running

```bash
docker compose ps
```

The `pulse` service should show as "healthy".

### 4. First-Time Setup (Bootstrap Token)

Pulse is secure by default. Get the bootstrap token:

```bash
docker compose exec pulse /app/pulse bootstrap-token
```

Then open http://localhost:7655, paste the token, and complete the Quick Security Setup wizard
(admin username/password plus an API token).

### 5. Add Infrastructure

Open **Settings → Infrastructure → Install on a host** to generate the per-host install command.
Proxmox VE, PBS, and PMG can be monitored API-only with a read-only token (no agent). Install the
unified agent only where you need agent-provided telemetry (Docker hosts, SMART/temperature, etc.).

### 6. Stop Pulse

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable            | Required | Description                                          |
| ------------------- | -------- | ---------------------------------------------------- |
| `PULSE_IMAGE`       | ❌       | Image tag (default `rcourtman/pulse:6.2.1`)          |
| `PULSE_PORT`        | ❌       | Host port (default `7655`, maps to 7655)             |
| `PULSE_TZ`          | ❌       | Container timezone (default `UTC`)                   |

### Volumes

| Volume                | Purpose                          |
| --------------------- | -------------------------------- |
| `pulse_data:/data`    | Pulse database, settings, history |

### Ports

| Port | Service        | Access                |
| ---- | -------------- | --------------------- |
| 7655 | Pulse web UI   | localhost by default  |

## Production Considerations

### Before Deploying to Production:

1. **Set the Bootstrap Token / Admin Credentials**

   The Quick Security Setup wizard sets your admin credentials and API token on first launch.
   Do not expose the instance to the internet before completing it.

2. **Bind Mount for Data**

   Uncomment the bind mount in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/pulse:/data
   ```

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

4. **HTTPS**

   Pulse has no built-in TLS. Put it behind a reverse proxy (see the
   [nginx-proxy-manager](../nginx-proxy-manager/), [Caddy](../caddy/), or [Traefik](../traefik/)
   stacks).

5. **Docker Monitoring**

   The Pulse server container does **not** need the Docker socket — install the unified agent on
   the Docker host instead.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs pulse
```

The healthcheck runs `wget` against the unauthenticated `/api/health` endpoint — an unhealthy
status usually means Pulse hasn't finished starting or port 7655 is already in use on the host.

### Port 7655 already in use

Change `PULSE_PORT` in `.env` and re-run `docker compose up -d`.

### Reset the data

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

### Lost the bootstrap token

Regenerate it:

```bash
docker compose exec pulse /app/pulse bootstrap-token
```

## Useful Commands

```bash
# View logs
docker compose logs -f pulse

# Regenerate the first-time setup token
docker compose exec pulse /app/pulse bootstrap-token

# Back up the data volume
docker run --rm -v pulse_pulse_data:/data -v "$PWD":/backup alpine tar czf /backup/pulse_data.tar.gz -C /data .
```

## Resources

- [Pulse on GitHub](https://github.com/rcourtman/Pulse)
- [Install and deployment docs](https://github.com/rcourtman/Pulse/blob/main/docs/INSTALL.md)
- [Production deployment and security](https://github.com/rcourtman/Pulse/blob/main/docs/PRODUCTION_SECURITY.md)
- [Official rcourtman/pulse image on Docker Hub](https://hub.docker.com/r/rcourtman/pulse)
