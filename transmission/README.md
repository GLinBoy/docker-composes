# Transmission

[Transmission](https://transmissionbt.com/) is a fast, lightweight BitTorrent client with a clean
web UI. This stack runs the [linuxserver/transmission image](https://hub.docker.com/r/linuxserver/transmission)
(Alpine + s6 overlay, ships `curl` and `transmission-remote`) with host bind mounts for config,
downloads and the watch folder, plus a custom network.

The healthcheck queries the RPC endpoint on `localhost:9091` — without a session id the daemon
answers `409`, which still proves it is listening (the check therefore does not use `curl -f`).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `linuxserver/transmission:4.1.3` by default. Set `PUID` / `PGID` to the
`id -u` / `id -g` of the user that should own the downloaded files (defaults to `1000`). Change
`TRANSMISSION_RPC_PORT` / `TRANSMISSION_PEER_PORT` if the defaults collide with another service.

### 2. Start Transmission

```bash
docker compose up -d
```

### 3. Verify Transmission is Running

```bash
docker compose ps
```

The `transmission` service should show as "healthy", and the Web UI should be up at
`http://localhost:9091/`.

### 4. Add a Torrent

- **Web UI** — open `http://localhost:9091/` and add it there.
- **Watch folder** — drop a `.torrent` file into `./watch/`; Transmission picks it up automatically
  and moves the file aside.

### 5. Stop Transmission

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Transmission start automatically, add `restart: unless-stopped` to the service.

## Data & Configuration

| Mount                | Purpose                                                    |
| -------------------- | ---------------------------------------------------------- |
| `./config:/config`   | Persistent config incl. `settings.json` and torrent state  |
| `./downloads:/downloads` | Completed downloads                                    |
| `./watch:/watch`     | Torrent files dropped here are added automatically         |

| Host port (env)                          | Container | Purpose                       |
| ---------------------------------------- | --------- | ----------------------------- |
| `TRANSMISSION_RPC_PORT` (9091)           | 9091      | Web UI / RPC (TCP)            |
| `TRANSMISSION_PEER_PORT` (51413)         | 51413     | Peer traffic (TCP + UDP)      |

`settings.json` lives in `./config/` and holds all daemon options. The daemon rewrites it on
shutdown, so **stop the stack before editing it by hand** (`docker compose stop`, edit,
`docker compose start`). Most settings can also be changed live from the Web UI.

## Updating

1. Bump `TRANSMISSION_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Transmission starts automatically on
boot or failure.

### 2. Protect the Web UI / RPC

The RPC interface has no password by default. Before exposing it beyond localhost, either
uncomment `USER` / `PASS` in `docker-compose.yml` (values from `.env`), or set
`rpc-authentication-required: true` plus `rpc-username` / `rpc-password` in `./config/settings.json`.
If you front it with a reverse proxy ([Traefik](../traefik/), [Caddy](../caddy/)), add
authentication middleware there instead.

### 3. Peer Port & Router Forwarding

For good download speeds, forward `TRANSMISSION_PEER_PORT` (TCP + UDP) on your router to the host.
Keep the value identical to the forwarded port — the container's internal peer port is fixed at
`51413` unless you also change `peer-port` in `settings.json` (or set the `PEERPORT` env var the
image supports).

### 4. Backup

`./config` (torrent state + settings) and `./downloads` (the payload) are your backup targets.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. BitTorrent is
network-bound more than CPU-bound; 1 CPU is usually plenty, disk I/O matters more.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs transmission
```

The healthcheck needs an HTTP answer from the RPC endpoint. If the daemon fails to start (bad
`settings.json`, unwritable `/config`), the logs show why.

### Web UI doesn't load

- `TRANSMISSION_RPC_PORT` changed? Browse `http://localhost:$TRANSMISSION_RPC_PORT/`.
- Another service already binds the host port — free it or pick another port in `.env`.

### Permission errors / downloads owned by the wrong user

Set `PUID` / `PGID` in `.env` to the owner of `./config`, `./downloads`, `./watch`
(`id -u`, `id -g`), then `docker compose up -d`. Existing files can be fixed with
`sudo chown -R $(id -u):$(id -g) downloads config watch`.

### No incoming peers / slow downloads

The peer port must be reachable from the internet: forward `TRANSMISSION_PEER_PORT` (TCP + UDP) on
your router to the host, and keep the same value in `.env`. Verify in the Web UI: the port icon
should turn green.

### My settings.json edits disappeared

The daemon rewrites `settings.json` on shutdown. Stop the stack first, edit, then start:

```bash
docker compose stop && nano config/settings.json && docker compose start
```

## Useful Commands

```bash
# View logs
docker compose logs -f transmission

# Shell access
docker exec -it transmission /bin/bash

# List torrents via the RPC (works from inside the container)
docker exec transmission transmission-remote 127.0.0.1:9091 -l

# Daemon stats
docker exec transmission transmission-remote 127.0.0.1:9091 -si
```

## Resources

- [Transmission website](https://transmissionbt.com/)
- [Transmission documentation](https://github.com/transmission/transmission/blob/main/docs/README.md)
- [linuxserver/transmission image docs](https://github.com/linuxserver/docker-transmission)
- [linuxserver/transmission on Docker Hub](https://hub.docker.com/r/linuxserver/transmission)