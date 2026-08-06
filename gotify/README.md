# Gotify

[Gotify](https://gotify.net/) is a simple, self-hosted push notification server written in Go. It
provides a WebUI, a REST API, and real-time delivery over WebSocket so you can send and receive
messages from any device — including the [official Android app](https://github.com/gotify/android).
This stack runs **Gotify 3.x** (`gotify/server` image) with a SQLite database, a named volume, and a
custom network. The default configuration needs no config file to get started.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port or timezone. The image is pinned to
`gotify/server:3.0.0` by default — bump `GOTIFY_IMAGE` to update.

### 2. Start Gotify

```bash
docker compose up -d
```

### 3. Verify Gotify is Running

```bash
docker compose ps
```

The `gotify` service should show as "healthy". The healthcheck curls the `/health` endpoint, which
returns HTTP 200 only when both the server and its database are healthy.

### 4. Log In

Open http://localhost:8080 in your browser. On first launch Gotify creates an initial admin account:

- Username: `admin` (or whatever you set via `GOTIFY_DEFAULTUSER_NAME`)
- Password: `admin` (or whatever you set via `GOTIFY_DEFAULTUSER_PASS`)

**Change the default password immediately after first login** — or set `GOTIFY_DEFAULTUSER_PASS` in
`.env` before the first start. The initial account is only created once; after that, manage users and
passwords from the WebUI.

### 5. Send a Test Push

In the WebUI, create an **Application** to get an app token, then push a message:

```bash
curl -s -X POST \
  "http://localhost:8080/message?token=<app-token>" \
  -F "title=Hello" \
  -F "message=World" \
  -F "priority=5"
```

### 6. Stop Gotify

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                  | Required | Description                                        |
| ------------------------- | -------- | -------------------------------------------------- |
| `GOTIFY_IMAGE`            | ❌       | Image tag (default `gotify/server:3.0.0`)          |
| `GOTIFY_PORT`             | ❌       | Host port (default `8080`, mapped to container 80) |
| `GOTIFY_DEFAULTUSER_NAME` | ❌       | Initial admin username (default `admin`)           |
| `GOTIFY_DEFAULTUSER_PASS` | ❌       | Initial admin password (default `admin`)           |
| `GOTIFY_REGISTRATION`     | ❌       | Allow public registration (default `false`)        |
| `GOTIFY_LOGLEVEL`         | ❌       | Log verbosity (default `info`)                     |
| `GOTIFY_TZ`               | ❌       | Container timezone (default `UTC`)                 |

### Volumes

| Volume                  | Purpose                                          |
| ----------------------- | ------------------------------------------------ |
| `gotify-data:/app/data` | SQLite database, uploaded images, certs, plugins |

### Ports

| Port | Service          | Access               |
| ---- | ---------------- | -------------------- |
| 8080 | Gotify WebUI/API | localhost by default |

## Production Considerations

### 1. Set a Strong Admin Password

Set `GOTIFY_DEFAULTUSER_PASS` in `.env` before the first start so the initial admin account is
created with a strong password:

```bash
openssl rand -hex 32
```

### 2. Keep Registration Disabled

Registration is disabled by default (`GOTIFY_REGISTRATION=false`). If you need self-service sign-up
(e.g. a family instance), enable it temporarily, then disable it again once accounts exist.

### 3. Bind Mount for Data

Uncomment the bind mount in `docker-compose.yml` for easier backup control:

```yaml
volumes:
  - /data/gotify:/app/data
```

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 5. HTTPS

Gotify can terminate TLS itself via Let's Encrypt, or you can put it behind a reverse proxy (see the
[reverse proxy docs](https://gotify.net/docs/)). To use Let's Encrypt, add these to the `gotify`
service's `environment:` block in `docker-compose.yml` (they are not referenced by this stack):

```yaml
environment:
  GOTIFY_SERVER_SSL_ENABLED: "true"
  GOTIFY_SERVER_SSL_LETSENCRYPT_ENABLED: "true"
  GOTIFY_SERVER_SSL_LETSENCRYPT_ACCEPTTOS: "true"
  GOTIFY_SERVER_SSL_LETSENCRYPT_HOSTS: gotify.example.com
  GOTIFY_SERVER_SECURECOOKIE: "true"
```

### 6. Using MySQL/PostgreSQL

The default SQLite database is fine for a single node. To use Postgres or MySQL, add to the `gotify`
service's `environment:` block and deploy a matching database service:

```yaml
environment:
  GOTIFY_DATABASE_DIALECT: postgres
  GOTIFY_DATABASE_CONNECTION: "host=db port=5432 user=gotify dbname=gotify password=secret sslmode=disable"
```

## Troubleshooting

### Container is unhealthy

```bash
docker compose logs gotify
```

The `/health` endpoint returns HTTP 500 (not 200) when the database is unreachable, so the container
will show as unhealthy. Check the data volume permissions.

### Port 8080 already in use

Change `GOTIFY_PORT` in `.env` and re-run `docker compose up -d`.

### Reset the database

Remove the named volume and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f gotify

# Push a message via the API (replace <app-token>)
curl -s -X POST "http://localhost:8080/message?token=<app-token>" \
  -F "title=Hello" -F "message=World"

# Check the running version
curl -s http://localhost:8080/version | jq
```

## Client Apps

- [Gotify Android](https://github.com/gotify/android) — official Android client
- [Gotify CLI](https://github.com/gotify/cli) — push messages from the command line
