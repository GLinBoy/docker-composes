# WildFly

[WildFly](https://www.wildfly.org/) is a lightweight, modular, open-source application server
implementing the latest Jakarta EE specifications. This stack runs the official
[quay.io/wildfly/wildfly](https://quay.io/repository/wildfly/wildfly) image (WildFly + Eclipse
Temurin JDK on a UBI-minimal base) in **standalone** mode.

The compose healthcheck probes the HTTP listener with `curl` (the ubi-minimal base ships it).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `quay.io/wildfly/wildfly:41.0.0.Final-jdk25` by default — bump
`WILDFLY_IMAGE` in `.env` when a new release is out. `latest`/`latest-jdk25` floating tags are also
maintained upstream.

### 2. Start WildFly

```bash
docker compose up -d
```

### 3. Verify WildFly is Running

```bash
docker compose ps
```

The `wildfly` service should show as "healthy", and the default welcome page is served at
`http://localhost:8080/`.

### 4. Deploy an Application

Drop a `.war`/`.ear` archive into `./deployments/` — the deployment scanner picks it up and deploys
it automatically:

```bash
cp your-app.war ./deployments/
```

Watch for the `your-app.war.deployed` marker (or `.failed` on error) in the same folder.

### 5. Stop the Stack

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have WildFly start automatically, add `restart: unless-stopped` to the service.

## Data & Configuration

| Mount                 | Container path                              | Purpose                         |
| --------------------- | ------------------------------------------- | ------------------------------- |
| `./deployments`       | `/opt/jboss/wildfly/standalone/deployments` | Deployment-scanner autodeploy   |

| Host port (env)                        | Container | Purpose          |
| -------------------------------------- | --------- | ---------------- |
| `WILDFLY_PORT` (8080)                  | 8080      | HTTP listener    |
| `WILDFLY_MANAGEMENT_PORT` (9990)       | 9990      | Management (see below) |

### Environment Variables

| Variable                  | Required | Description                                                      |
| ------------------------- | -------- | ---------------------------------------------------------------- |
| `WILDFLY_IMAGE`           | ❌       | Image tag (default `quay.io/wildfly/wildfly:41.0.0.Final-jdk25`) |
| `WILDFLY_PORT`            | ❌       | Host port for HTTP (default `8080`, maps to 8080)                |
| `WILDFLY_MANAGEMENT_PORT` | ❌       | Host port for management (default `9990`, maps to 9990)          |
| `TZ`                      | ❌       | Container timezone (default `UTC`)                               |

## Management Console (port 9990)

**The stock image does not make the admin console usable out of the box.** Two things are missing:

1. **No admin user** — older `jboss/wildfly` images accepted `WILDFLY_USER`/`WILDFLY_PASS`, but the
   current `quay.io/wildfly/wildfly` image ignores those variables entirely.
2. **Management binds to localhost** — the default command is
   `standalone.sh -b 0.0.0.0`, which opens the HTTP listener (8080) but leaves the management
   interface bound to the container's loopback.

To enable it, extend the image with a small `Dockerfile` — exactly as the
[upstream docs](https://github.com/wildfly/wildfly-container) recommend:

```dockerfile
FROM quay.io/wildfly/wildfly:41.0.0.Final-jdk25

RUN --mount=type=secret,id=ADMIN_USER,env=ADMIN_USER,required=true \
    --mount=type=secret,id=ADMIN_PASSWORD,env=ADMIN_PASSWORD,required=true \
    $JBOSS_HOME/bin/add-user.sh -u ${ADMIN_USER} -p ${ADMIN_PASSWORD} --silent

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
```

Build it, point `WILDFLY_IMAGE` at it, and the console will be available at
`http://localhost:9990/`:

```bash
ADMIN_USER=admin ADMIN_PASSWORD='Admin#70365' \
  docker build --secret id=ADMIN_USER --secret id=ADMIN_PASSWORD -t my-wildfly .
# then set WILDFLY_IMAGE=my-wildfly in .env
```

> `add-user.sh` rejects weak passwords (it must contain letters, a digit, and a symbol).

## Updating

1. Bump `WILDFLY_IMAGE` in `.env` (e.g. `41.0.0.Final-jdk25` → `41.0.1.Final-jdk25`) — check
   [Quay tags](https://quay.io/repository/wildfly/wildfly/tags) and
   [WildFly releases](https://www.wildfly.org/news/).
2. Pull and recreate:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. HTTPS

Terminate TLS with a reverse proxy ([Traefik](../traefik/), [Caddy](../caddy/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) and, once proxied, consider unpublishing the ports.
The admin console (when enabled) should never be exposed to the internet — keep reachable only
through the proxy network with strong credentials.

### 2. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so the server comes back automatically
after a reboot.

### 3. Admin Credentials

The `admin`/`Admin#70365` example above is for local testing only — on a server always generate a
strong password (e.g. `openssl rand -hex 24`) and prefer Docker build secrets over plain build
args.

### 4. Backups

`./deployments` holds the applications you shipped. Server configuration lives inside the image,
so to preserve `standalone.xml` edits you must bake them into your custom image (see the management
console section) or mount a config file — include both in your backup strategy.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` block. WildFly is a JVM server — give it room: 1–2G of
memory is a reasonable starting point.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs wildfly
```

The healthcheck needs a successful response on `http://localhost:8080/`. WildFly can take 30–60s
to boot on slow hosts — increase `start_period` in the healthcheck if it keeps flipping to
"unhealthy" before the welcome page is up.

### Application does not deploy

Verify the archive is a valid `.war`/`.ear` in `./deployments` and check for a `.failed` marker
next to it, then look at the logs:

```bash
docker compose logs wildfly | grep -i -E "deploy|error"
```

### Management console unreachable at localhost:9990

Expected with the stock image — see [Management Console](#management-console-port-9990). The
container's mgmt interface binds to its own loopback, so the published port does nothing until you
extend the image with an admin user and `-bmanagement 0.0.0.0`.

### Port already in use

Change `WILDFLY_PORT` / `WILDFLY_MANAGEMENT_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f wildfly

# Shell access
docker compose exec wildfly /bin/bash

# Verify the HTTP listener directly
curl -s http://localhost:8080/

# Check server state with the management CLI (from inside the container)
docker compose exec wildfly $JBOSS_HOME/bin/jboss-cli.sh --connect \
  --command=":read-attribute(name=server-state)"
```

## Resources

- [WildFly website](https://www.wildfly.org/)
- [WildFly docs](https://docs.wildfly.org/)
- [quay.io/wildfly/wildfly tags](https://quay.io/repository/wildfly/wildfly/tags)
- [wildfly/wildfly-container source](https://github.com/wildfly/wildfly-container)