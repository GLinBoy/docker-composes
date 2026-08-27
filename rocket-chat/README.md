# Rocket.Chat

[Rocket.Chat](https://www.rocket.chat/) is an open-source team communication platform with
channels, direct messages, voice and video calls, and omnichannel support. This stack runs the
official Rocket.Chat image backed by the official `mongodb/mongodb-community-server` image in a
single-node replica set, as recommended by the [Rocket.Chat documentation](https://docs.rocket.chat/).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum `ROOT_URL` to the URL you will use to reach the workspace. The
images are pinned to `registry.rocket.chat/rocketchat/rocket.chat:8.7.1` and
`mongodb/mongodb-community-server:8.2-ubi8` by default — bump `ROCKETCHAT_IMAGE` /
`MONGODB_IMAGE` to update.

### 2. Start Rocket.Chat

```bash
docker compose up -d
```

On the first start the stack runs two one-shot containers: `mongodb-permissions` fixes the data
volume ownership and `mongodb-init` initiates the MongoDB replica set. MongoDB must be healthy and
the replica set initialized before Rocket.Chat starts (handled via `depends_on`).

### 3. Verify Rocket.Chat is Running

```bash
docker compose ps
```

The `rocketchat` and `mongodb` services should show as "healthy".

### 4. Access Rocket.Chat

Open the URL from `ROOT_URL` (default `http://localhost:3000`). On first load a setup wizard
prompts you to create the admin account.

### 5. Stop Rocket.Chat

```bash
docker compose down
# Remove the named volume too (deletes all data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                        | Required | Description                                                                  |
| ------------------------------- | -------- | ---------------------------------------------------------------------------- |
| `ROCKETCHAT_IMAGE`              | ❌       | Rocket.Chat image tag (default `.../rocket.chat:8.7.1`)                      |
| `MONGODB_IMAGE`                 | ❌       | MongoDB image tag (default `mongodb-community-server:8.2-ubi8`)              |
| `ROOT_URL`                      | ❌       | Public URL of the workspace (default `http://localhost:3000`)                |
| `PORT`                          | ❌       | In-container Rocket.Chat port (default `3000`)                               |
| `ROCKETCHAT_PORT`               | ❌       | Host port for Rocket.Chat (default `3000`)                                   |
| `BIND_IP`                       | ❌       | Host IP the Rocket.Chat port binds to (default `0.0.0.0`)                    |
| `REG_TOKEN`                     | ❌       | Optional registration token                                                  |
| `MONGODB_USER_ID`               | ❌       | MongoDB user UID in the image (default `1001`)                               |
| `MONGODB_PORT`                  | ❌       | Host port for MongoDB, bound to 127.0.0.1 (default `27017`)                  |
| `MONGODB_REPLICA_SET_NAME`      | ❌       | Replica set name (default `rs0`)                                             |
| `MONGODB_ADVERTISED_HOSTNAME`   | ❌       | Hostname advertised to replica set members (default `mongodb`)               |
| `MONGO_URL`                     | ❌       | Optional full MongoDB connection string override                             |
| `ROCKETCHAT_DOMAIN`             | ❌       | Domain for the Traefik route (only if using Traefik)                         |

### Volumes

| Volume        | Purpose                                    |
| ------------- | ------------------------------------------ |
| `mongodb_data`| Rocket.Chat database (MongoDB `/data/db`)  |

### Ports

| Port | Service      | Access                |
| ---- | ------------ | --------------------- |
| 3000 | Rocket.Chat  | Host (default 0.0.0.0)|
| 27017| MongoDB      | Bound to 127.0.0.1    |

## MongoDB Replica Set

Rocket.Chat requires a MongoDB replica set. The `mongodb` service runs `mongod --replSet rs0`
and the one-shot `mongodb-init` container calls `rs.initiate()` on first start. The replica set
configuration is persisted in the `mongodb_data` volume, so it is only initialized once.

## Updating

1. Bump `ROCKETCHAT_IMAGE` (and `MONGODB_IMAGE` if required) in `.env`.
2. Check the [Rocket.Chat upgrade guidelines](https://docs.rocket.chat/docs/guidelines-for-updating-rocketchat)
   for database compatibility before major upgrades.
3. Pull and recreate the containers:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set `ROOT_URL` to the real HTTPS URL (e.g. `https://chat.example.com`)
- [ ] Do not expose port 27017 to the public internet (it is bound to 127.0.0.1 by default)
- [ ] If using Traefik, set `ROCKETCHAT_DOMAIN` and share the network with the Traefik instance
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` blocks on the services
- [ ] Uncomment the bind mount for `mongodb_data` for easier backup control

## Resources

- [Rocket.Chat documentation](https://docs.rocket.chat/)
- [Rocket.Chat official compose repository](https://github.com/RocketChat/rocketchat-compose)
- [Deploy with Docker and Docker Compose](https://docs.rocket.chat/docs/deploy-with-docker-docker-compose)
