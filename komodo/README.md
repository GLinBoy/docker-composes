# Komodo

[Komodo](https://komo.do/) is a build and deployment automation platform with server
monitoring. This stack deploys its three components:

| Service     | Container          | Purpose                                          |
| ----------- | ------------------ | ------------------------------------------------ |
| `mongo`     | `komodo-mongo`     | MongoDB database storing all Komodo data         |
| `core`      | `komodo-core`      | Web UI + API (port 9120)                         |
| `periphery` | `komodo-periphery` | Agent that manages this host's Docker containers |

Core and Periphery authenticate each other with a shared passkey, and Periphery talks to the
Docker socket — see [Production Considerations](#production-considerations) before exposing
anything publicly.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Then fill in at least `KOMODO_DB_PASSWORD` and `KOMODO_PASSKEY` (`openssl rand -hex 32`).
Images are pinned to Komodo `2.3.2` and MongoDB `8.0.29` — bump them in `.env` to update.

### 2. Start the Stack

```bash
docker compose up -d
```

### 3. Verify Komodo is Running

```bash
docker compose ps
```

All three services should show as "healthy" (Mongo may take ~30s on first start while it
initializes). The Komodo UI is then available at `http://localhost:9120/`.

### 4. Log In

On first launch Komodo creates the "first server" (`https://periphery:8120`) automatically.
Register the first user with the **signup** button in the UI — or uncomment
`KOMODO_INIT_ADMIN_USERNAME` / `KOMODO_INIT_ADMIN_PASSWORD` in `.env` **before the first
start** to have an admin created for you.

### 5. Stop the Stack

```bash
docker compose down
# Remove the data volumes too:
docker compose down -v
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Komodo start automatically, uncomment the `restart: unless-stopped` lines in
> `docker-compose.yml`.

## Configuration

### Environment Variables

| Variable                   | Required | Description                                                    |
| -------------------------- | -------- | -------------------------------------------------------------- |
| `KOMODO_CORE_IMAGE`        | ❌       | Core image tag (default `ghcr.io/moghtech/komodo-core:2.3.2`)  |
| `KOMODO_PERIPHERY_IMAGE`   | ❌       | Periphery image tag (default `...komodo-periphery:2.3.2`)      |
| `MONGO_IMAGE`              | ❌       | Mongo image tag (default `mongo:8.0.29`)                       |
| `KOMODO_PORT`              | ❌       | Host port for the UI/API (default `9120`, maps to 9120)        |
| `KOMODO_DB_USERNAME`       | ✅       | MongoDB root username (only applied on first start)            |
| `KOMODO_DB_PASSWORD`       | ✅       | MongoDB root password (only applied on first start)            |
| `KOMODO_PASSKEY`           | ✅       | Shared Core ↔ Periphery auth secret                            |
| `KOMODO_JWT_SECRET`        | ➖       | Core JWT signing secret — set in production                    |
| `KOMODO_WEBHOOK_SECRET`    | ➖       | Core webhook auth secret — set in production                   |
| `KOMODO_BACKUPS_PATH`      | ❌       | Host path for dated DB backups (default `/etc/komodo/backups`) |
| `PERIPHERY_ROOT_DIRECTORY` | ❌       | Periphery agent root (default `/etc/komodo`, same path in/out) |
| `TZ`                       | ❌       | Container timezone (default `UTC`)                             |

### Extra Core / Periphery Config

`core` and `periphery` receive the **whole `.env` file** via `env_file`, so any
`KOMODO_*` / `PERIPHERY_*` variable can be added directly to `.env` — no compose edits needed.
Full variable lists: [core.config.toml](https://github.com/moghtech/komodo/blob/main/config/core.config.toml),
[periphery.config.toml](https://github.com/moghtech/komodo/blob/main/config/periphery.config.toml).

> Note: the explicit `environment:` entries in `docker-compose.yml` (DB address/credentials,
> `PERIPHERY_PASSKEYS`, `TZ`) always override values set in `.env`.

### Volumes & Ports

| Volume         | Container path   | Purpose                          |
| -------------- | ---------------- | -------------------------------- |
| `mongo_data`   | `/data/db`       | MongoDB data (all Komodo state)  |
| `mongo_config` | `/data/configdb` | MongoDB config                   |

| Port                  | Service   | Access                                                 |
| --------------------- | --------- | ------------------------------------------------------ |
| `KOMODO_PORT` (9120)  | core      | Web UI + API                                           |
| 8120 (not published)  | periphery | Internal — Core reaches it at `https://periphery:8120` |

### Adding More Servers

Each managed host runs one Periphery agent (this stack covers the local host). To add other
servers, install the Periphery agent there — container or systemd binary, see the
[Periphery docs](https://komo.do/docs) — then register it in the Komodo UI under
**Servers → Add Server** using `https://<host>:8120` and the same `KOMODO_PASSKEY`.

## Production Considerations

### 1. Set All Secrets Before First Start

```bash
# .env
KOMODO_DB_PASSWORD=<openssl rand -hex 32>
KOMODO_PASSKEY=<openssl rand -hex 32>
KOMODO_JWT_SECRET=<openssl rand -hex 32>
KOMODO_WEBHOOK_SECRET=<openssl rand -hex 32>
```

Without `KOMODO_PASSKEY`, Periphery accepts **unauthenticated** connections. Note that
`KOMODO_DB_USERNAME` / `KOMODO_DB_PASSWORD` only take effect on the very first start (empty
`mongo_data` volume) — to rotate them later, update the MongoDB user or recreate the volume.

### 2. Periphery Is Powerful

Periphery mounts `/var/run/docker.sock` and `/proc` — it has full control over the host's
Docker daemon. Never publish port 8120 without the passkey configured, and keep Periphery off
public networks (use a VPN/[Wireguard](../wireguard/) for cross-host connections).

### 3. Backups

- Core writes dated database backups to `KOMODO_BACKUPS_PATH` (configure in the UI under
  **Resources → Settings → Database** — see the [backup docs](https://komo.do/docs/setup/backup)).
- The raw volume can be dumped with:
  `docker run --rm -v komodo_mongo_data:/data -v "$PWD":/backup alpine tar czf /backup/mongo_data.tar.gz -C /data .`

### 4. HTTPS for the UI

Put Core behind a reverse proxy (see [Traefik](../traefik/), [Caddy](../caddy/), or
[Nginx Proxy Manager](../nginx-proxy-manager/)) and set `KOMODO_HOST=https://komodo.example.com`
in `.env` for correct OAuth / webhook URLs.

### 5. Restart Policy & Resource Limits

Uncomment the `restart: unless-stopped` lines and tune the commented `deploy.resources` blocks
in `docker-compose.yml` for production.

## Migrating from the Old Setup (compose.env)

Older versions of this stack used `compose.env` + hyphenated volume names. To migrate an
existing deployment:

1. Rename your `compose.env` to `.env` and merge in the new variables from `.env.example`
   (`KOMODO_CORE_IMAGE` / `KOMODO_PERIPHERY_IMAGE` replace `COMPOSE_KOMODO_IMAGE_TAG`).
2. Keep the old data by copying the volumes to their new names (`mongo-data` → `mongo_data`,
   `mongo-config` → `mongo_config`), e.g.:
   `docker run --rm -v komodo_mongo-data:/from -v komodo_mongo_data:/to alpine sh -c 'cd /from && cp -a . /to'`
   — or edit the volume names back in `docker-compose.yml`.
3. `docker compose up -d` and verify the UI still shows your resources.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs mongo      # DB auth/init issues
docker compose logs core       # UI/API issues
docker compose logs periphery  # agent issues
```

- **mongo**: usually bad credentials on an already-initialized volume — see the note in
  [Production Considerations](#1-set-all-secrets-before-first-start).
- **core**: the healthcheck curls `http://localhost:9120/`; check DB connectivity in the logs.
- **periphery**: the healthcheck curls `https://localhost:8120/` (self-signed SSL, hence `-k`);
  if you set `PERIPHERY_SSL_ENABLED=false`, adjust the check accordingly.

### Periphery not connecting to Core

1. `PERIPHERY_PASSKEYS` (periphery) must equal `KOMODO_PASSKEY` (core).
2. The server in the UI must use `https://` (not `http://`) when `PERIPHERY_SSL_ENABLED=true`.
3. First-server registration uses `https://periphery:8120` — the compose service name.

### Port already in use

Change `KOMODO_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# Follow all logs
docker compose logs -f

# Open a Mongo shell
docker compose exec mongo mongosh -u "$KOMODO_DB_USERNAME" -p "$KOMODO_DB_PASSWORD" admin

# Manually trigger a Core database backup
docker compose exec core core database backup
```

## Resources

- [Komodo website & docs](https://komo.do/)
- [Komodo on GitHub](https://github.com/moghtech/komodo)
- [komodo-core image (ghcr)](https://github.com/moghtech/komodo/pkgs/container/komodo-core)
- [MongoDB image on Docker Hub](https://hub.docker.com/_/mongo)
