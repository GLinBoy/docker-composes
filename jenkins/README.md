# Jenkins

[Jenkins](https://www.jenkins.io) is an open-source automation server for building, testing, and
deploying software — CI/CD pipelines driven by everything from shell steps to distributed build
agents. This stack runs the official [jenkins/jenkins image](https://hub.docker.com/r/jenkins/jenkins)
(Debian-based, `eclipse-temurin` JDK) with a named volume for the Jenkins home, a mount of the host
Docker socket so Jenkins can drive host Docker, and a custom network.

The container runs as **root** so it can talk to the host Docker socket (`/var/run/docker.sock`). The
official image runs as uid `1000` by default; mounting the socket needs a privileged user. The image
ships `curl`, which the healthcheck uses against the web UI's `/login` endpoint.

> **Security note:** mounting `/var/run/docker.sock` gives the container control over the host's
> Docker daemon (root-equivalent on the host). Only deploy this where you trust who can manage
> Jenkins.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `jenkins/jenkins:2.576-jdk25` by default. Bump `JENKINS_VERSION` to update.
Change `JENKINS_PORT` / `JENKINS_AGENT_PORT` if the defaults collide with other services.

### 2. Start Jenkins

```bash
docker compose up -d
```

### 3. Verify Jenkins is Running

```bash
docker compose ps
```

The `jenkins` service should show as "healthy". First boot can be slow (Jenkins unpacks and may fetch
plugins), so allow up to the 90s start period before deciding it is stuck.

### 4. Unlock Jenkins

Open `http://localhost:8080` — Jenkins asks for an initial admin password:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Follow the wizard to install suggested plugins and create your admin user.

### 5. Stop Jenkins

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Jenkins start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable              | Required | Description                                                               |
| --------------------- | -------- | ------------------------------------------------------------------------- |
| `JENKINS_VERSION`     | ❌       | Image tag (default `jenkins/jenkins:2.576-jdk25`)                          |
| `JENKINS_PORT`        | ❌       | Host port for the web UI, mapped to container 8080 (default `8080`)        |
| `JENKINS_AGENT_PORT`  | ❌       | Host port for inbound build agents, mapped to container 50000 (default `50000`) |
| `JENKINS_TZ`          | ❌       | Container timezone (default `UTC`)                                         |

> The container's `8080` (web) and `50000` (agents) ports are fixed; the env vars only change the
> host side so they don't collide with other services.

### Volumes

| Volume                     | Purpose                                  |
| -------------------------- | ---------------------------------------- |
| `jenkins_home:/var/jenkins_home` | Jenkins config, jobs, plugins, credentials |
| `/var/run/docker.sock:/var/run/docker.sock` | Host Docker daemon socket (bind mount) |

### Ports

| Port | Service | Access                             |
| ---- | ------- | ---------------------------------- |
| 8080 | Jenkins | Web UI and REST API (TCP)          |
| 50000| Jenkins | Inbound build agents (JNLP) (TCP)  |

## Updating

Jenkins images bundle the full distro, so 1) bump `JENKINS_VERSION` in `.env` and 2) recreate:

```bash
docker compose pull
docker compose up -d
```

Refer to Jenkins' own [upgrade guide](https://www.jenkins.io/doc/book/upgrading/) for plugin
compatibility before jumping major versions.

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Jenkins starts automatically on boot
or failure.

### 2. Bind Mount for jenkins_home

Uncomment the bind mount driver options in `docker-compose.yml` for simpler backups:

```yaml
volumes:
  jenkins_home:
    driver_opts:
      type: none
      o: bind
      device: /data/jenkins/jenkins_home
```

Back up `/var/jenkins_home` regularly (`jobs/`, `plugins/`, `secrets/`, `config.xml`) — it is your
entire Jenkins state.

### 3. Docker CLI Inside the Container

The image has no `docker` binary, so pipelines that invoke `docker` need it mounted from the host:

```yaml
volumes:
  - /usr/bin/docker:/usr/bin/docker
  - /var/run/docker.sock:/var/run/docker.sock
```

Alternatively, delegate builds to separate agent containers that run Docker themselves.

### 4. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. Builds are CPU- and
memory-hungry — size it for your heaviest pipeline and adjust `JAVA_OPTS`/`JENKINS_OPTS` if needed:

```yaml
environment:
  - JAVA_OPTS=-Dhudson.model.DownloadService.noSignatureCheck=true -Xmx2g
```

### 5. Reverse Proxy

Put Jenkins behind one of the reverse-proxy stacks ([Caddy](../caddy/), [Traefik](../traefik/),
[Nginx Proxy Manager](../nginx-proxy-manager/)) for automatic TLS. If you do, keep
`CAS_...`/proxy defaults in Jenkins ("Manage Jenkins → Security") matching the externally visible URL
so links and CSRF tokens are correct.

## Troubleshooting

### Container stays unhealthy on first boot

```bash
docker compose logs jenkins
```

The healthcheck requests `http://localhost:8080/login`; Jenkins is slow to start the first time while
it initializes `/var/jenkins_home` and installs plugins. If `start_period` (90s) is too short, raise
it in `docker-compose.yml`.

### Forgot the admin password

Reset it by editing `/var/jenkins_home/users/<user>/config.xml` (clear the
`passwordHash` value) or restoring from a backup of `jenkins_home`.

### Pipeline can't talk to Docker

Confirm the socket is mounted (`/var/run/docker.sock`) and that host Docker works from the container:

```bash
docker exec -it jenkins docker version || echo "no docker CLI — mount /usr/bin/docker"
```

### Port 8080 or 50000 already in use

Change `JENKINS_PORT` / `JENKINS_AGENT_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs
docker compose logs -f jenkins

# Shell access (container runs as root)
docker exec -it jenkins /bin/bash

# Read the initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Check the web UI
curl -sf http://localhost:8080/login

# Container version
docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.version" }}' jenkins
```

## Resources

- [Jenkins website](https://www.jenkins.io)
- [Jenkins Docker install docs](https://www.jenkins.io/doc/book/installing/docker/)
- [Jenkins upgrade guide](https://www.jenkins.io/doc/book/upgrading/)
- [jenkins/jenkins image on Docker Hub](https://hub.docker.com/r/jenkins/jenkins)