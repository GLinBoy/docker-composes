# MongoDB

[MongoDB](https://www.mongodb.com/) is a general-purpose, document-oriented, NoSQL
database. It stores data in flexible JSON-like documents, making it a popular choice for
applications with evolving schemas.

This stack runs a MongoDB server and [mongo-express](https://github.com/mongo-express/mongo-express),
a web-based admin interface for browsing and managing your databases.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `MONGO_ROOT_PASSWORD` - generate with `openssl rand -hex 32`
- `MONGOEXPRESS_PASSWORD` - generate with `openssl rand -hex 32`

Optionally change:

- `MONGO_ROOT_USER` - the MongoDB root admin username
- `MONGO_PORT` - the host port for MongoDB (default `27017`)
- `MONGO_EXPRESS_PORT` - the host port for the web UI (default `8081`)

> Change the passwords BEFORE first start. If you change them after MongoDB has already
> initialized the data volume, the credentials stored in the database will no longer match.

### 2. Start MongoDB

```bash
docker compose up -d
```

### 3. Verify MongoDB is Running

```bash
docker compose ps
```

All services should show as "healthy".

### 4. Access the Web UI

Open http://localhost:8081 and log in with `MONGOEXPRESS_LOGIN` / `MONGOEXPRESS_PASSWORD`.

### 5. Connect via mongosh

From the host (any MongoDB client):

```bash
mongosh "mongodb://root:YOUR_PASSWORD@localhost:27017/admin"
```

### 6. View Logs

```bash
docker compose logs -f mongo
```

### 7. Stop MongoDB

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have MongoDB start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable               | Required | Description                                                      |
| ---------------------- | -------- | ---------------------------------------------------------------- |
| `MONGO_ROOT_USER`      | ✅       | MongoDB root admin username                                      |
| `MONGO_ROOT_PASSWORD`  | ✅       | MongoDB root admin password                                      |
| `MONGOEXPRESS_LOGIN`   | ✅       | mongo-express web UI username                                    |
| `MONGOEXPRESS_PASSWORD`| ✅       | mongo-express web UI password                                    |
| `MONGO_IMAGE`          | ❌       | MongoDB image (exact-pinned, default: `mongo:8.2.12`)            |
| `MONGO_EXPRESS_IMAGE`  | ❌       | mongo-express image (exact-pinned, default: `mongo-express:1.0.2-20-alpine3.19`) |
| `MONGO_PORT`           | ❌       | Host port for MongoDB (default: `27017`)                         |
| `MONGO_EXPRESS_PORT`   | ❌       | Host port for the web UI (default: `8081`)                       |
| `TZ`                   | ❌       | Timezone (default: `Etc/UTC`)                                    |

### Volumes

| Volume       | Purpose                     |
| ------------ | --------------------------- |
| `mongo_data` | MongoDB database files      |

### Ports

| Port | Purpose                        |
| ---- | ------------------------------ |
| 27017 | MongoDB server               |
| 8081  | mongo-express web UI         |

## Connecting from Another Container

Services in the same Docker network can reach MongoDB using the service name `mongo`:

```yaml
services:
  myapp:
    networks:
      - mongodb-network
    environment:
      MONGO_URL: mongodb://root:${MONGO_ROOT_PASSWORD}@mongo:27017
```

## Updating

1. Bump `MONGO_IMAGE` in `.env` to the next release (e.g. `8.3.0`).
2. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set strong `MONGO_ROOT_PASSWORD` and `MONGOEXPRESS_PASSWORD` in `.env`
- [ ] Add `restart: unless-stopped` to every service if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Do not expose ports 27017/8081 to the public internet
- [ ] Terminate TLS with a reverse proxy if exposing mongo-express publicly
- [ ] Review the [MongoDB backup guide](https://www.mongodb.com/docs/manual/core/backups/) for `mongo_data`
