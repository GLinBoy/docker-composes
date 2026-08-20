# Jetty

[Jetty](https://jetty.org) is a lightweight, embeddable Java HTTP server and servlet container — a
production-grade alternative to Tomcat for running Java EE / Jakarta EE web applications. This stack
runs the official [jetty image](https://hub.docker.com/r/jetty/jetty) (Debian-based `eclipse-temurin`
JDK) with host bind mounts so you can drop your applications in directly, plus a custom network.

Jetty 12 serves applications as **WAR files** deployed from `$JETTY_BASE/webapps`. The image ships no
`curl`/`wget`, so the healthcheck uses `bash`'s `/dev/tcp` to make a real HTTP request to the
connector. The image runs as uid `999` (`jetty` user).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `jetty:12.1.12-jdk25` by default (the current `latest`). Change
`JETTY_PORT` if `8080` collides with another service.

### 2. Start Jetty

```bash
docker compose up -d
```

### 3. Verify Jetty is Running

```bash
docker compose ps
```

The `jetty` service should show as "healthy". With no webapp deployed yet, `http://localhost:8080/`
returns `404` — that's expected; Jetty has nothing to serve yet.

### 4. Deploy Your Application

See [Running your application](#running-your-application) below.

### 5. Stop Jetty

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Jetty start automatically, add `restart: unless-stopped` to the service.

## Running your application

This stack's job is to host your Java application. Which packaging you use decides how it runs.

### Java EE / Jakarta EE application (WAR)

Jetty deploys **WAR** files. Build your webapp (any Java EE / Servlet project, e.g.:

```bash
mvn clean package        # -> target/myapp.war
# or
./gradlew bootWar        # Spring Boot WAR packaging
```

then drop the WAR into the deploy directory and restart (the deploy scanner does **not**
hot-redeploy):

```bash
cp target/myapp.war data/wars/
mv data/wars/myapp.war data/webapps/
docker compose restart jetty
```

The WAR's filename sets its context path:

| WAR filename | URL                     |
| ------------ | ----------------------- |
| `ROOT.war`   | `http://localhost:8080/` |
| `myapp.war`  | `http://localhost:8080/myapp` |

Deploy a test WAR to confirm the pipeline works, then point your browser at it (the container runs as
uid `999`, so build the WAR in the container's temp dir and copy it out rather than writing directly
into the host deploy directory):

```bash
docker exec jetty sh -c 'mkdir -p /tmp/w && printf "<html><body>hello</body></html>" > /tmp/w/index.html && cd /tmp/w && jar -cf /tmp/jetty/ROOT.war .' \
  && docker cp jetty:/tmp/jetty/ROOT.war data/webapps/ \
  && docker compose restart jetty \
  && curl -sf http://localhost:8080/   # -> hello
```

### Spring Boot application (JAR)

A Spring Boot **fat JAR** embeds its own server, so it does not deploy into Jetty as a webapp. Pick
the right option for your case:

- **Recommended — package it as a WAR** and deploy it like any other webapp (see above). Spring Boot
  supports WAR packaging out of the box (`war` packaging + `SpringBootServletInitializer`).
- **Standalone executable JAR** — run it on the JDK this image provides, replacing the Jetty server
  process with your embedded server. Create a `compose.override.yml` next to `docker-compose.yml`
  (Compose picks it up automatically):

  ```yaml
  # compose.override.yml — run a Spring Boot fat jar instead of the servlet container
  services:
    jetty:
      entrypoint: ["java", "-jar"]
      command: ["/var/lib/jetty/wars/myapp.jar"]
  ```

  ```bash
  cp target/myapp.jar data/wars/
  docker compose up -d
  curl -sf http://localhost:8080/      # your app's endpoint
  ```

  > Both Web UI and the JAR bind container port `8080` — the override replaces one with the other;
  > they cannot run side by side on the same port. `compose.override.yml` is local-only, so keep it
  > out of version control (it is gitignored along with `.env`).

## Configuration

### Environment Variables

| Variable         | Required | Description                                                            |
| ---------------- | -------- | ---------------------------------------------------------------------- |
| `JETTY_VERSION`  | ❌       | Image tag (default `jetty:12.1.12-jdk25`)                               |
| `JETTY_PORT`     | ❌       | Host port for the web server, mapped to container 8080 (default `8080`) |
| `JETTY_TZ`       | ❌       | Container timezone (default `UTC`)                                      |

### Volumes

| Volume                  | Purpose                                                    |
| ----------------------- | ---------------------------------------------------------- |
| `./data/webapps:/var/lib/jetty/webapps` | Deploy directory — Jetty serves every WAR found here |
| `./data/wars:/var/lib/jetty/wars`       | Staging area for WAR files before moving them into webapps |
| `./data/etc:/var/lib/jetty/etc`         | Optional custom server config XMLs                         |

### Ports

| Port | Service | Access              |
| ---- | ------- | ------------------- |
| 8080 | Jetty   | HTTP web apps (TCP) |

## Updating

1. Bump `JETTY_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Jetty starts automatically on boot or
failure.

### 2. Backup the Deploy Directory

`./data/webapps` holds your deployed applications and `./data/wars` the source archives — keep them
in your regular backup. Server config you add to `./data/etc` is part of your deployment as well.

### 3. Modules & Tuning

The stack enables `ee10-deploy` ("Servlet 6.0 / Jakarta EE 10") so WARs deploy out of the box. To
add JSP, annotations, JMX, TLS, or another module, extend the `command` list, e.g.:

```yaml
command: ["--modules=ee10-deploy,ee10-jsp"]
```

Persistent settings belong in `$JETTY_BASE/start.d/*.ini` files.

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml` to cap JVM heap and thread
usage (`jetty.threadPool.maxThreads` defaults to 200).

### 5. Reverse Proxy

Put Jetty behind one of the reverse-proxy stacks ([Caddy](../caddy/), [Traefik](../traefik/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) for automatic TLS. Map it to the same
`JETTY_PORT` you publish.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs jetty
```

The healthcheck sends a `GET /` request to the connector; the connector only starts once Jetty has
finished booting. If startup is unusually slow, raise `start_period` in `docker-compose.yml`.

### My WAR doesn't appear at its URL

- The deploy scanner does not hot-redeploy — run `docker compose restart jetty` after placing a WAR.
- Confirm the file is in `data/webapps/` (not `data/wars/`), matches `*.war`, and has a sensible
  context path (`ROOT.war` → `/`, `myapp.war` → `/myapp`).
- Check the logs for a deploy error:

```bash
docker compose logs jetty | grep -i -E "deploy|webapp|warn|error"
```

### Spring Boot JAR exits immediately

Enable the embedded server's logs to see the real error:

```bash
docker compose logs jetty
```

A common cause is another process already bound to `8080` inside the container — the JAR cannot
share the port with the running Jetty server.

### Port already in use

Change `JETTY_PORT` in `.env` and re-run

```bash
docker compose up -d
```

## Useful Commands

```bash
# View logs
docker compose logs -f jetty

# Shell access (uid 999 — use sudo for writes that need it)
docker exec -it jetty /bin/bash

# List currently deployed webapps
docker exec jetty ls -la /var/lib/jetty/webapps

# Hot-check the server without restarting
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/
```

## Resources

- [Jetty website](https://jetty.org)
- [Jetty documentation](https://jetty.org/docs/)
- [Jetty Docker image docs](https://github.com/docker-library/docs/tree/master/jetty)
- [jetty image on Docker Hub](https://hub.docker.com/r/jetty/jetty)