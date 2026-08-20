# IT-Tools

[IT-Tools](https://it-tools.tech) is a collection of handy online tools for developers and IT
professionals — hashing, encoding, JWT decoding, color converters, QR codes, and much more — with a
clean, fast web UI. This stack runs the official [corentinth/it-tools
image](https://hub.docker.com/r/corentinth/it-tools) (nginx-based, Alpine) on a custom network.

IT-Tools is a **stateless static web app**: the app is baked into the image, so no data volume is
required and the container can be recreated at any time without losing anything.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port. The image is pinned to
`corentinth/it-tools:2024.10.22-7ca5933` by default — bump `IT_TOOLS_VERSION` to update.

### 2. Start IT-Tools

```bash
docker compose up -d
```

### 3. Verify IT-Tools is Running

```bash
docker compose ps
```

The `it-tools` service should show as "healthy".

### 4. Access the Web UI

Open `http://localhost:8080`.

### 5. Stop IT-Tools

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have IT-Tools start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable          | Required | Description                                                                 |
| ----------------- | -------- | --------------------------------------------------------------------------- |
| `IT_TOOLS_VERSION`| ❌       | Image tag (default `corentinth/it-tools:2024.10.22-7ca5933`)                |
| `IT_TOOLS_PORT`   | ❌       | Host port for the web UI (default `8080`, mapped to container 80)           |

### Volumes

No volumes are required — the application is entirely static and baked into the image.

### Ports

| Port | Service | Access      |
| ---- | ------- | ----------- |
| 8080 | IT-Tools| Web UI      |

## Updating

1. Bump `IT_TOOLS_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so IT-Tools starts automatically on
boot or failure.

### 2. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 3. Reverse Proxy & Authentication

Put IT-Tools behind one of the reverse-proxy stacks ([Caddy](../caddy/), [Traefik](../traefik/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) to get automatic TLS and add authentication at the
proxy if you want to restrict access.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs it-tools
```

The healthcheck requests `http://localhost/`; a failure usually means the container is still
starting or nginx failed to bind.

### Port 8080 already in use

Change `IT_TOOLS_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f it-tools

# Shell access
docker exec -it it-tools /bin/sh

# Verify nginx serves the app
curl -sf http://localhost:8080/ | head
```

## Resources

- [IT-Tools website](https://it-tools.tech)
- [IT-Tools GitHub repository](https://github.com/CorentinTh/it-tools)
- [corentinth/it-tools image on Docker Hub](https://hub.docker.com/r/corentinth/it-tools)