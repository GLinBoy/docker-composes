# Firefox

[Firefox](https://www.mozilla.org/en-US/firefox/) is a free and open-source web browser by Mozilla.
This stack runs Firefox in a containerized desktop environment using the
[linuxserver.io Firefox image](https://hub.docker.com/r/linuxserver/firefox), so you can access a
full Firefox browser from any device over your network via the web UI.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

By default no secrets are needed. Optionally change:

- `FIREFOX_VERSION` - the exact image version to run (defaults to `latest` when unset)
- `FIREFOX_HTTP_PORT` / `FIREFOX_HTTPS_PORT` - host ports for the web UI
- `PUID` / `PGID` - your host user/group id (`id -u` / `id -g`)
- `FIREFOX_CLI` - Firefox CLI flags passed on launch (e.g. a homepage URL)
- `FIREFOX_USER` / `FIREFOX_PASSWORD` - optional HTTP Basic auth (see [Security](#security))
- `FIREFOX_TZ` - the timezone (default `UTC`)

### 2. Start Firefox

```bash
docker compose up -d
```

### 3. Verify Firefox is Running

```bash
docker compose ps
```

The service should show as "healthy".

### 4. Open the Web UI

Open **https://localhost:3001** in your browser. You may need to accept the self-signed
certificate warning — this is expected (the image serves HTTPS with a self-signed cert by default).

### 5. View Logs

```bash
docker compose logs -f firefox
```

### 6. Stop Firefox

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention). To
> have Firefox start automatically, uncomment `restart: unless-stopped` on the service.

## Configuration

### Environment Variables

| Variable               | Required | Description                                                          |
| ---------------------- | -------- | -------------------------------------------------------------------- |
| `FIREFOX_VERSION`      | ❌       | Exact image version (defaults to `latest` when unset)                |
| `FIREFOX_HTTP_PORT`    | ❌       | Host port for the HTTP web UI (default: `3000`)                      |
| `FIREFOX_HTTPS_PORT`   | ❌       | Host port for the HTTPS web UI (default: `3001`)                     |
| `PUID`                 | ❌       | User ID the container processes run as (default: `1000`)             |
| `PGID`                 | ❌       | Group ID the container processes run as (default: `1000`)            |
| `FIREFOX_CLI`          | ❌       | Firefox CLI flags passed on launch (default: `https://google.com`)   |
| `FIREFOX_USER`         | ❌       | Web UI username (requires uncommenting in compose)                   |
| `FIREFOX_PASSWORD`     | ❌       | Web UI password (requires uncommenting in compose)                   |
| `FIREFOX_TZ`           | ❌       | Timezone (default: `UTC`)                                            |

### Volumes

| Volume               | Purpose                                            |
| -------------------- | -------------------------------------------------- |
| `firefox_config`     | Firefox profile, settings and downloaded files (`/config`) |

### Ports

| Port | Service        | Access               |
| ---- | -------------- | -------------------- |
| 3000 | Web UI (HTTP)  | redirects to HTTPS   |
| 3001 | Web UI (HTTPS) | main access point    |

## Security

> **Warning:** This container provides privileged access to the host system. The web interface
> includes a terminal with passwordless `sudo` access — any user with GUI access can gain root
> control inside the container. **Do not expose it to the Internet.**

- By default there is **no authentication**. To enable HTTP Basic auth, uncomment
  `CUSTOM_USER` / `PASSWORD` in `docker-compose.yml` and set `FIREFOX_USER` / `FIREFOX_PASSWORD`
  in `.env`:

  ```yaml
  environment:
    - CUSTOM_USER=${FIREFOX_USER}
    - PASSWORD=${FIREFOX_PASSWORD}
  ```

- For Internet exposure, place the container behind a reverse proxy (Caddy/Nginx/Traefik) with
  HTTPS termination and a robust authentication mechanism.
- The `seccomp:unconfined` security option is required by the image for browser syscalls to work.
  It weakens the container's isolation — avoid running it alongside untrusted workloads.

## Updating

1. Bump `FIREFOX_VERSION` in `.env` to the next release (e.g. `1154.0.0`).
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Enable HTTP Basic auth (`FIREFOX_USER` / `FIREFOX_PASSWORD`) and uncomment the env lines
- [ ] Place the container behind a reverse proxy with HTTPS — do not expose ports 3000/3001 directly
- [ ] Set `PUID` / `PGID` to a dedicated service user, not `1000:1000`
- [ ] Add `restart: unless-stopped` to the service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Consider a bind mount for `firefox_config` for easier backup control

## Resources

- [linuxserver/firefox on GitHub](https://github.com/linuxserver/docker-firefox)
- [linuxserver/firefox on Docker Hub](https://hub.docker.com/r/linuxserver/firefox)
- [Firefox](https://www.mozilla.org/en-US/firefox/)
