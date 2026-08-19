# HAProxy

[HAProxy](https://www.haproxy.org/) is a free, very fast and reliable solution offering high
availability, load balancing, and proxying for TCP and HTTP-based applications. This stack runs
the official `haproxy` image (Alpine variant) with a bind-mounted `haproxy.cfg` configuration and a
custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the exposed port or image version. The image is pinned to
`haproxy:3.4.3-alpine3.24` by default — bump `HAPROXY_IMAGE` to update.

### 2. Configure HAProxy

Edit `data/haproxy.cfg` to match your backends. The bundled config load-balances across up to
six servers each on the `service1` and `service2` hostnames (resolved via Docker's embedded DNS):

```haproxy
backend service
    balance roundrobin
    server-template service1- 6 service1:80 check resolvers docker_resolver init-addr libc,none
    server-template service2- 6 service2:80 check resolvers docker_resolver init-addr libc,none
```

Add backend containers to the `haproxy-network` network and they will be discovered automatically.
Remove or adjust any `server-template` lines you don't need.

A HAProxy stats page is enabled at `http://localhost:<HAPROXY_PORT>/my-stats`.

### 3. Start HAProxy

```bash
docker compose up -d
```

### 4. Verify HAProxy is Running

```bash
docker compose ps
```

The `haproxy` service should show as "healthy".

### 5. Test It

```bash
# Stats page (default port 8080)
curl http://localhost:8080/my-stats
```

### 6. Stop HAProxy

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have HAProxy start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable        | Required | Description                                          |
| --------------- | -------- | ---------------------------------------------------- |
| `HAPROXY_IMAGE` | ❌       | Image tag (default `haproxy:3.4.3-alpine3.24`)       |
| `HAPROXY_PORT`  | ❌       | Host port (default `8080`, mapped to container 80)   |

### Volumes

| Volume                     | Purpose                              |
| -------------------------- | ------------------------------------ |
| `./data/haproxy.cfg`       | HAProxy configuration (bind mount)   |

### Ports

| Port | Service | Access               |
| ---- | ------- | -------------------- |
| 80   | HAProxy | `HAPROXY_PORT` on the host (default `8080`) |

## Updating

1. Bump `HAPROXY_IMAGE` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so HAProxy starts automatically on boot
or failure.

### 2. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 3. TLS Termination

HAProxy can terminate TLS on its own — add certificate files and a `bind *:443 ssl` frontend line to
`haproxy.cfg`. For a simpler managed option, put HAProxy behind one of the reverse-proxy stacks
([Caddy](../caddy/), [Traefik](../traefik/), [Nginx Proxy Manager](../nginx-proxy-manager/)).

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs haproxy
```

The healthcheck probes TCP port 80; a failure usually means HAProxy failed to start or is still
starting.

### Config errors

Validate your configuration before (re)starting:

```bash
docker compose exec haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
```

### Port 8080 already in use

Change `HAPROXY_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f haproxy

# Reload configuration without downtime
docker compose exec haproxy kill -USR2 1

# Check the running version
docker compose exec haproxy haproxy -v
```

## Resources

- [HAProxy Documentation](https://docs.haproxy.org/)
- [Official haproxy image on Docker Hub](https://hub.docker.com/_/haproxy)
