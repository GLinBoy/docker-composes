# Caddy

[Caddy](https://caddyserver.com/) is a powerful, enterprise-ready, open source web server with automatic HTTPS written in Go.

## Quick Start

### 1. Create a Caddyfile

Before starting Caddy, create a `Caddyfile` in this directory to define your site configuration:

```bash
# Example Caddyfile for local development
localhost:80 {
    respond "Hello from Caddy!"
}
```

### 2. Start Caddy

```bash
docker compose up -d
```

### 3. Verify Caddy is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Test Your Configuration

```bash
# Test HTTP response
curl http://localhost

# Check Caddy metrics (admin API)
curl http://localhost:2019/metrics
```

### 5. Stop Caddy

```bash
docker compose down
```

## Configuration

### Caddyfile

The Caddyfile is the configuration file for Caddy. Mount your Caddyfile to `/etc/caddy/Caddyfile` inside the container.

Example Caddyfile for reverse proxy:

```caddyfile
localhost:80 {
    reverse_proxy backend-service:8080
}
```

Example Caddyfile with automatic HTTPS (production):

```caddyfile
example.com {
    reverse_proxy backend-service:8080
}
```

### Volumes

| Volume | Purpose |
|--------|---------|
| `./Caddyfile:/etc/caddy/Caddyfile:ro` | Caddy configuration file (read-only) |
| `caddy_data:/data` | SSL certificates and site data |
| `caddy_config:/config` | Caddy runtime configuration |

### Ports

| Port | Purpose |
|------|---------|
| 80 | HTTP traffic |
| 443 | HTTPS traffic (automatic with Caddy) |
| 2019 | Caddy admin API (internal) |

## Production Considerations

### Before Deploying to Production:

1. **Set Your Email Address**
   
   Set the `CADDY_EMAIL` environment variable in `.env` to receive important notifications from Let's Encrypt:
   
   ```bash
   CADDY_EMAIL=your-email@example.com
   ```

2. **Agree to ACME Terms of Service**
   
   Set `ACME_AGREE=true` in your `.env` file to automatically agree to the ACME TOS.

3. **Configure Firewall Rules**
   
   Ensure ports 80 and 443 are open on your server firewall.

4. **Resource Limits**
   
   Uncomment the `deploy.resources` block in `docker-compose.yml` and adjust CPU/memory limits based on your expected traffic.

5. **Bind Mounts for Data**
   
   Consider using bind mounts instead of named volumes for easier backup and management:
   
   ```yaml
   volumes:
     - /data/caddy/data:/data
     - /data/caddy/config:/config
   ```

6. **DNS Configuration**
   
   Ensure your domain's DNS records point to your server's IP address before enabling HTTPS.

7. **Test SSL Certificate Issuance**
   
   After starting Caddy with your production domain, verify the certificate:
   
   ```bash
   curl -vI https://your-domain.com
   ```

## Troubleshooting

### Caddy won't start

Check the logs:
```bash
docker compose logs caddy
```

### SSL certificates not issuing

- Ensure port 80 is accessible from the internet (Let's Encrypt needs to validate)
- Check DNS records are correctly configured
- Verify `ACME_AGREE=true` is set

### Admin API not accessible

The admin API listens on `localhost:2019` inside the container. To access it from outside, you can add port mapping:
```yaml
ports:
  - "2019:2019"
```

## Useful Commands

```bash
# View logs
docker compose logs -f caddy

# Reload Caddy configuration (without downtime)
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

# View Caddy version
docker compose exec caddy caddy version

# Test Caddyfile syntax
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
```

## Resources

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Caddyfile Syntax](https://caddyserver.com/docs/caddyfile)
- [Caddy API](https://caddyserver.com/docs/api)
- [Automatic HTTPS](https://caddyserver.com/docs/automatic-https)