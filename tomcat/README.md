# Tomcat

[Apache Tomcat](https://tomcat.apache.org/) is the reference open-source Jakarta Servlet container —
one of the most widely used servers for Java web applications. This stack runs the official
[tomcat image](https://hub.docker.com/_/tomcat) (Ubuntu `noble`-based `eclipse-temurin` JRE 25) with
host bind mounts for deployed applications and logs, plus a custom network.

The image ships no `curl`/`wget`, so the healthcheck uses `bash`'s `/dev/tcp` to make a real HTTP
request to the connector — it passes even with no webapp deployed, because a bare Tomcat still
answers `404` with an `HTTP/1.1` status line. The container runs as **root** (the image defines no
`USER`), so bind-mount writes just work without UID gymnastics.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `tomcat:11.0.24-jre25` by default. Change `TOMCAT_PORT` if `8080` collides
with another service.

### 2. Start Tomcat

```bash
docker compose up -d
```

### 3. Verify Tomcat is Running

```bash
docker compose ps
```

The `tomcat` service should show as "healthy". With no webapp deployed yet, `http://localhost:8080/`
returns `404` — that's expected; the bind mount hides the image's default `ROOT` app.

### 4. Deploy Your Application

See [Running your application](#running-your-application) below.

### 5. Stop Tomcat

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Tomcat start automatically, add `restart: unless-stopped` to the service.

## Running your application

Tomcat serves **WAR** files (or exploded webapp directories) deployed from `webapps`.

Build your webapp first:

```bash
mvn clean package        # -> target/myapp.war
# or
./gradlew bootWar        # Spring Boot WAR packaging
```

then copy it into the deploy directory. Tomcat's `autoDeploy` (enabled by default) picks it up
within ~10 seconds; `docker compose restart tomcat` is the deterministic alternative:

```bash
cp target/myapp.war data/webapps/
docker compose restart tomcat
```

The WAR's filename sets its context path:

| WAR filename | URL                            |
| ------------ | ------------------------------ |
| `ROOT.war`   | `http://localhost:8080/`       |
| `myapp.war`  | `http://localhost:8080/myapp`  |

Deploy a test app to confirm the pipeline works, then point your browser at it (the container runs
as root, so you can also write `index.html` straight into `data/webapps/ROOT/`):

```bash
mkdir -p data/webapps/ROOT && printf '<html><body>hello</body></html>' > data/webapps/ROOT/index.html \
  && curl -sf http://localhost:8080/   # -> hello
```

### Spring Boot application (JAR)

A Spring Boot **fat JAR** embeds its own server, so it does not deploy into Tomcat as a webapp. Pick
the right option for your case:

- **Recommended — package it as a WAR** and deploy it like any other webapp (see above). Spring Boot
  supports WAR packaging out of the box (`war` packaging + `SpringBootServletInitializer`).
- **Standalone executable JAR** — run it on the JRE this image provides, replacing the Tomcat server
  process with your embedded server. Create a `compose.override.yml`:

```yaml
services:
  tomcat:
    command: ["java", "-jar", "/webapps/myapp.jar"]
    volumes:
      - ./data/jars:/webapps
```

## Data & Configuration

| Mount                                  | Purpose                                                   |
| -------------------------------------- | --------------------------------------------------------- |
| `./data/webapps:/usr/local/tomcat/webapps` | Deployed applications (WARs / exploded directories)   |
| `./data/logs:/usr/local/tomcat/logs`   | Tomcat logs (`catalina.out`, `localhost.*.log`, ...)      |

> The `webapps` bind mount hides the image's bundled apps (`ROOT`, `docs`, `examples`, `manager`,
> `host-manager`). To restore the manager app, copy it out of a clean container from the same image:
>
> ```bash
> docker create --name tomcat-clean tomcat:11.0.24-jre25
> docker cp tomcat-clean:/usr/local/tomcat/webapps/manager data/webapps/
> docker rm tomcat-clean
> ```
>
> # SERVER: The manager apps expose deployment/shutdown endpoints — protect them (strong
> credentials in `conf/tomcat-users.xml`, network ACLs) or leave them out entirely.

### Ports

| Port | Service | Access              |
| ---- | ------- | ------------------- |
| 8080 | Tomcat  | HTTP web apps (TCP) |

## Updating

1. Bump `TOMCAT_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Tomcat starts automatically on boot or
failure.

### 2. Backup the Deploy Directory

`./data/webapps` holds your deployed applications — keep it in your regular backup. Logs in
`./data/logs` are reproducible, but include them if you need audit trails.

### 3. JVM Memory

The JVM defaults its heap to ¼ of the RAM it sees. Cap it explicitly with `JAVA_OPTS`, and align the
container memory limit with it:

```yaml
environment:
  - JAVA_OPTS=-Xms256m -Xmx768m
```

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

### 5. Reverse Proxy

Put Tomcat behind one of the reverse-proxy stacks ([Caddy](../caddy/), [Traefik](../traefik/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) for automatic TLS. Map it to the same `TOMCAT_PORT`
you publish. Alternatively enable Tomcat's TLS connector via a custom `server.xml` mounted into
`/usr/local/tomcat/conf/`.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs tomcat
```

The healthcheck sends a `GET /` request to the connector; the connector only starts once Tomcat has
finished booting. If startup is unusually slow (large apps, slow disks), raise `start_period` in
`docker-compose.yml`.

### My WAR doesn't appear at its URL

- Confirm the file is directly in `data/webapps/` and matches `*.war`.
- Check the context path: `ROOT.war` → `/`, `myapp.war` → `/myapp`.
- Wait ~10 seconds (`autoDeploy` polls) or run `docker compose restart tomcat`.
- Check the logs for a deploy error — `data/logs/localhost.*.log` and `catalina.out`:

```bash
docker compose logs tomcat | grep -i -E "deploy|severe|error"
```

### Permission errors on bind mounts

The container runs as root, so it can read/write the host directories. If you deploy as a non-root
user and Tomcat's unpacked webapps end up root-owned, clean them with sudo between deploys, or
unpack the WAR yourself before copying it in.

### Port already in use

Change `TOMCAT_PORT` in `.env` and re-run

```bash
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f tomcat

# Shell access (container runs as root)
docker exec -it tomcat /bin/bash

# List currently deployed webapps
docker exec tomcat ls -la /usr/local/tomcat/webapps

# Validate server config after edits
docker exec tomcat catalina.sh configtest

# Hot-check the server without restarting
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/
```

## Resources

- [Tomcat website](https://tomcat.apache.org/)
- [Tomcat documentation](https://tomcat.apache.org/tomcat-11.0-doc/)
- [Tomcat Docker image docs](https://github.com/docker-library/docs/tree/master/tomcat)
- [tomcat image on Docker Hub](https://hub.docker.com/_/tomcat)