# Apache

[Apache HTTP Server](https://httpd.apache.org/) is the world's most widely used web server. This stack
runs the official `httpd` image (Alpine variant) with a named volume for web content and a custom
network. Serving files is as simple as dropping them into the `apache-www` volume's `htdocs`.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port or timezone. The image is pinned to
`httpd:2.4.68-alpine3.23` by default — bump `APACHE_IMAGE` to update.

### 2. Start Apache

```bash
docker compose up -d
```

### 3. Verify Apache is Running

```bash
docker compose ps
```

The `apache` service should show as "healthy".

### 4. Serve Content

Add files to the web root (mounted at `/usr/local/apache2/htdocs` inside the container):

```bash
# Copy a file into the named volume
docker cp ./index.html apache:/usr/local/apache2/htdocs/index.html

# Or inspect where the volume lives on the host
docker volume inspect apache_apache-www
```

### 5. Test It

```bash
curl http://localhost
```

### 6. Stop Apache

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable       | Required | Description                                            |
| -------------- | -------- | ------------------------------------------------------ |
| `APACHE_IMAGE` | ❌       | Image tag (default `httpd:2.4.68-alpine3.23`)          |
| `APACHE_PORT`  | ❌       | Host port (default `80`, mapped to container 80)       |
| `APACHE_TZ`    | ❌       | Container timezone (default `UTC`)                     |

### Volumes

| Volume                   | Purpose                         |
| ------------------------ | ------------------------------- |
| `apache-www:/usr/local/apache2/htdocs` | Web content root (`DocumentRoot`) |

### Ports

| Port | Service          | Access               |
| ---- | ---------------- | -------------------- |
| 80   | Apache HTTP      | localhost by default |

## Production Considerations

### 1. HTTPS

Apache does not terminate TLS on its own here. Put it behind a reverse proxy (see the
[nginx-proxy-manager](../nginx-proxy-manager/), [Caddy](../caddy/), or [Traefik](../traefik/)
stacks), or supply your own certificate and uncomment the relevant SSL directives in the Apache
configuration.

### 2. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Apache starts automatically on boot or
failure.

### 3. Bind Mount for Content

Uncomment the bind mount in `docker-compose.yml` for easier management and backup of your web files:

```yaml
volumes:
  - /data/apache/htdocs:/usr/local/apache2/htdocs
```

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs apache
```

The healthcheck uses `wget --spider` against the local listener; a failure usually means Apache is
still starting or failed to bind.

### Port 80 already in use

Change `APACHE_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f apache

# Execute commands inside the container
docker compose exec apache ls /usr/local/apache2/htdocs

# Check the running version
docker compose exec apache httpd -v
```

## Resources

- [Apache HTTP Server documentation](https://httpd.apache.org/docs/)
- [Official httpd image on Docker Hub](https://hub.docker.com/_/httpd)
