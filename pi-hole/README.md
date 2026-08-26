# Pi-hole

[Pi-hole](https://pi-hole.net/) is a network-wide ad blocker and DNS server. This stack runs the
official `pihole/pihole` image (v6) with named volumes and a custom network. It blocks ads for every
device that uses it as its DNS server.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set `PIHOLE_WEBPASSWORD` to a strong password — leaving it empty **disables** the web
interface password entirely. The image is pinned to `pihole/pihole:2026.07.2` by default — bump
`PIHOLE_IMAGE` to update.

### 2. Start Pi-hole

```bash
docker compose up -d
```

### 3. Verify Pi-hole is Running

```bash
docker compose ps
```

The `pihole` service should show as "healthy".

### 4. Log In to the Admin Web Interface

Open http://localhost/admin and log in with the password you set in `PIHOLE_WEBPASSWORD`.

### 5. Point Your Devices at Pi-hole

Set the DNS server of your devices, or the DHCP server on your router, to this host's IP. Open
http://pi.hole/admin to confirm queries are being blocked.

### 6. Stop Pi-hole

```bash
docker compose down
# Remove the named volumes too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable            | Required | Description                                                     |
| ------------------- | -------- | --------------------------------------------------------------- |
| `PIHOLE_IMAGE`      | ❌       | Image tag (default `pihole/pihole:2026.07.2`)                   |
| `PIHOLE_WEBPASSWORD`| ⚠️       | Web interface password (empty **disables** web auth)            |
| `PIHOLE_DNS_PORT`   | ❌       | Host DNS port (default `53`, maps to 53)                        |
| `PIHOLE_WEB_PORT`   | ❌       | Host web port (default `80`, maps to 80)                        |
| `PIHOLE_DHCP_PORT`  | ❌       | Host DHCP port (default `67`; commented out in compose)         |
| `PIHOLE_TZ`         | ❌       | Container timezone (default `UTC`)                              |

### Volumes

| Volume                     | Purpose                          |
| -------------------------- | -------------------------------- |
| `pihole_etc:/etc/pihole`       | Pi-hole databases and config |
| `pihole_dnsmasq:/etc/dnsmasq.d` | Custom dnsmasq config files  |

### Ports

| Port | Service        | Access                |
| ---- | -------------- | --------------------- |
| 53   | DNS (TCP/UDP)  | all devices on network |
| 80   | Admin web UI   | localhost by default  |
| 67   | DHCP (UDP)     | commented out by default |

## Production Considerations

### Before Deploying to Production:

1. **Set a Strong Password**

   In `.env`:

   ```bash
   PIHOLE_WEBPASSWORD=openssl rand -hex 32
   ```

   Leaving `PIHOLE_WEBPASSWORD` empty disables authentication on the web interface — anyone on the
   network could reconfigure Pi-hole.

2. **Bind Mount for Data**

   Uncomment the bind mounts in `docker-compose.yml` for easier backup control:

   ```yaml
   volumes:
     - /data/pihole/etc:/etc/pihole
     - /data/pihole/dnsmasq:/etc/dnsmasq.d
   ```

3. **Resource Limits**

   Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

4. **DHCP Server**

   DHCP runs best with host networking. Uncomment `PIHOLE_DHCP_PORT` in `.env` and the `67/udp`
   port mapping in `docker-compose.yml`, or switch to `network_mode: host` (see the
   [DHCP documentation](https://docs.pi-hole.net/docker/DHCP/)).

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs pihole
```

The healthcheck runs `dig` against the container's own DNS port — an unhealthy status usually means
FTL hasn't finished starting or port 53 is already taken on the host.

### Port 53 already in use

A local resolver such as `systemd-resolved` may already be bound to port 53. Disable it
(see [Tips and Tricks](https://docs.pi-hole.net/docker/tips-and-tricks/)) or change `PIHOLE_DNS_PORT`
in `.env` and configure your devices to use that port.

### Reset the data

Remove the named volumes and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f pihole

# Back up the data volumes
docker run --rm -v pi-hole_pihole_etc:/data -v "$PWD":/backup alpine tar czf /backup/pihole_etc.tar.gz -C /data .
docker run --rm -v pi-hole_pihole_dnsmasq:/data -v "$PWD":/backup alpine tar czf /backup/pihole_dnsmasq.tar.gz -C /data .
```

## Resources

- [Pi-hole documentation](https://docs.pi-hole.net/)
- [Docker Pi-hole on GitHub](https://github.com/pi-hole/docker-pi-hole)
- [Official pihole/pihole image on Docker Hub](https://hub.docker.com/r/pihole/pihole)
