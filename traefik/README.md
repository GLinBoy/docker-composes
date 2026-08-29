# Traefik

[Traefik](https://traefik.io/traefik/) is a modern cloud-native edge router / reverse proxy: it
discovers services automatically and routes requests to them. This stack runs the official
[traefik image](https://hub.docker.com/_/traefik) (Alpine-based) with the **Docker provider** —
routing is declared with labels on containers, one service at a time
(`exposedbydefault=false`) — plus a `whoami` demo service proving the pipeline works.

The healthcheck uses Traefik's built-in `traefik healthcheck --ping` command against the
`--ping=true` endpoint (no `curl`/`wget` needed). The dashboard/API is enabled in **insecure** mode
on `:8080` for local convenience — see [Secure the Dashboard](#2-secure-the-dashboard) before
deploying to a server.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `traefik:3.7.10` by default. Change `TRAEFIK_HTTP_PORT` if `80` or
`TRAEFIK_DASHBOARD_PORT` if `8080` collide with another service.

### 2. Start Traefik

```bash
docker compose up -d
```

### 3. Verify Traefik is Running

```bash
docker compose ps
```

The `traefik` service should show as "healthy" (`whoami` shows no health status — its image is
built from scratch and cannot run an in-container probe).

### 4. Try the Routing Demo

Request the demo service through the `web` entrypoint by presenting its router's Host:

```bash
curl -H 'Host: whoami.localhost' http://localhost/
```

You should get a response listing the request headers Traefik forwarded (your browser works too —
`*.localhost` resolves to `127.0.0.1` on Linux and modern browsers). The dashboard is at
`http://localhost:8080/`.

### 5. Stop the Stack

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Traefik start automatically, add `restart: unless-stopped` to the service.

## Exposing Your Own Services

Any container on the `traefik-network` can publish itself with labels. For a stack in another
folder, join Traefik's network as an external network and opt in with labels:

```yaml
# In the other stack's docker-compose.yml
services:
  my-app:
    # ... image, ports (optional — only Traefik needs to reach it), ...
    networks:
      - default
      - traefik-network
    labels:
      - traefik.enable=true
      - traefik.http.routers.my-app.rule=Host(`myapp.localhost`)   # or your public domain
      - traefik.http.routers.my-app.entrypoints=web

networks:
  traefik-network:
    external: true
    name: traefik_traefik-network
```

Then `docker network connect` is not needed — just `docker compose up -d` in both folders. Sibling
stacks in this repository (e.g. [Tomcat](../tomcat/), [Grafana](../grafana/)) can be wired in the
same way; add their service to the network and set the router rule to their host/port.

## Data & Configuration

| Mount                                          | Purpose                                              |
| ---------------------------------------------- | ---------------------------------------------------- |
| `/var/run/docker.sock:/var/run/docker.sock:ro` | Watch containers & read routing labels (read-only)   |

| Host port (env)                            | Container | Purpose                          |
| ------------------------------------------ | --------- | -------------------------------- |
| `TRAEFIK_HTTP_PORT` (80)                   | 80        | `web` entrypoint — routed traffic |
| `TRAEFIK_DASHBOARD_PORT` (8080)            | 8080      | Dashboard/API (`api.insecure`) + `/ping` |

All Traefik static configuration lives in the `command:` flags of `docker-compose.yml`; per-router
configuration lives in container labels. For larger setups you can switch to a mounted
`traefik.yml` file provider — see the [Traefik docs](https://docs.traefik.io/reference/static-configuration/).

## Updating

1. Bump `TRAEFIK_VERSION` (and `WHOAMI_VERSION`) in `.env` to the next release.
2. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Traefik starts automatically on boot
or failure. As your edge router it is usually the one service you *do* want auto-started.

### 2. Secure the Dashboard

`api.insecure=true` serves the dashboard and API **without authentication** on `:8080`. For a
server, replace it with the secure form — a router with authentication:

```yaml
command:
  - --api.dashboard=true
  # ... (keep entrypoints / providers / ping flags)
labels:
  - traefik.enable=true
  - traefik.http.routers.dashboard.rule=Host(`traefik.example.com`)
  - traefik.http.routers.dashboard.service=api@internal
  - traefik.http.routers.dashboard.middlewares=dash-auth
  # SERVER: generate with `htpasswd -nB admin` (bcrypt) or echo a strong hash
  - traefik.http.middlewares.dash-auth.basicauth.users=admin:$$2y$$05$$...
```

Also keep `TRAEFIK_DASHBOARD_PORT` unpublished (remove the ports entry) if the dashboard should
only be reachable through a router.

### 3. TLS with Let's Encrypt

Add a TLS entrypoint and a certificate resolver, mount `acme.json`, and switch routers to
`websecure`:

```yaml
command:
  - --entrypoints.websecure.address=:443
  - --entrypoints.web.http.redirections.entrypoint.to=websecure
  - --certificatesresolvers.letsencrypt.acme.email=you@example.com
  - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
  - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
volumes:
  - ./data/letsencrypt:/letsencrypt
ports:
  - "${TRAEFIK_HTTP_PORT:-80}:80"
  - "${TRAEFIK_HTTPS_PORT:-443}:443"
```

```bash
mkdir -p data/letsencrypt && touch data/letsencrypt/acme.json && chmod 600 data/letsencrypt/acme.json
```

Then add to each routed service: `traefik.http.routers.<name>.tls.certresolver=letsencrypt`.

### 4. Docker Socket Exposure

The socket is mounted **read-only**, which is Traefik's documented requirement for the Docker
provider — but any container with it can list/manage Docker. For hardened setups use a socket
proxy (e.g. [tecnativa/docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy)) and
point `--providers.docker.endpoint=tcp://socket-proxy:2375` at it instead.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` blocks in `docker-compose.yml`.

## Troubleshooting

### `whoami.localhost` doesn't respond

- `*.localhost` resolves on Linux and modern browsers; for other devices or plain `curl` use the
  Host header: `curl -H 'Host: whoami.localhost' http://localhost/`.
- Check the router exists: `curl -s http://localhost:8080/api/http/routers | grep whoami`.
- The `whoami` container must be on `traefik-network` and have `traefik.enable=true`.

### My other service's router doesn't appear

- `exposedbydefault=false` — the container needs `traefik.enable=true`.
- The container must share a network with Traefik (`traefik-network`); an internal-only network is
  invisible to the Docker provider.
- Check `docker compose logs traefik` for provider errors (bad label syntax is reported there).

### Dashboard doesn't load

- `TRAEFIK_DASHBOARD_PORT` changed? Browse `http://localhost:$TRAEFIK_DASHBOARD_PORT/`.
- Another service already binds the host port — free it or pick another port in `.env`.

### Container stays unhealthy

```bash
docker compose logs traefik
```

The healthcheck calls `http://:8080/ping`. If you changed ports or disabled the ping endpoint
(remove `--ping=true`), restore it or adjust the check.

## Useful Commands

```bash
# View routing logs
docker compose logs -f traefik

# Inspect discovered routers / services via the API
curl -s http://localhost:8080/api/http/routers | tr ',' '\n' | grep -E '"(name|status)"'
curl -s http://localhost:8080/api/http/services | tr ',' '\n' | grep -E '"(name|status)"'

# Run the health check manually
docker exec traefik traefik healthcheck --ping

# Show effective static configuration
docker exec traefik traefik version
```

## Resources

- [Traefik website](https://traefik.io/traefik/)
- [Traefik documentation](https://docs.traefik.io/)
- [Docker provider reference](https://docs.traefik.io/reference/install-configuration/providers/docker/)
- [traefik image on Docker Hub](https://hub.docker.com/_/traefik)
- [traefik/whoami demo app](https://github.com/traefik/whoami)