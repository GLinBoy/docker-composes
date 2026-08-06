# GitLab CE

[GitLab](https://about.gitlab.com/) is a self-hosted DevOps platform with source code
management, issue tracking, CI/CD, container registry, and more. This stack runs the official
GitLab Community Edition (CE) Docker image, which bundles its own PostgreSQL, Redis, Gitaly, and
nginx — all in a single container.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `GITLAB_VERSION` - the exact GitLab CE version to run (defaults to `latest` when unset)
- `GITLAB_EXTERNAL_URL` - the URL users will use to reach GitLab (default `http://localhost`)
- `GITLAB_SSH_PORT` - the SSH port (default `22`); GitLab uses this in SSH clone URLs

Optionally change:

- `GITLAB_HTTP_PORT` / `GITLAB_HTTPS_PORT` - host ports for HTTP/HTTPS (defaults `80`/`443`)
- `GITLAB_ROOT_PASSWORD` - initial password for the `root` user (only on first boot)
- `TZ` - the container timezone (default `UTC`)

### 2. Start GitLab

```bash
docker compose up -d
```

First boot runs the full omnibus reconfigure and database migrations, which can take **3-10
minutes** — the container is not usable until it finishes.

### 3. Verify GitLab is Running

```bash
docker compose ps
```

The service should show as "healthy" once the web server is up.

### 4. Sign In

Open your `GITLAB_EXTERNAL_URL` in a browser and sign in with the username `root`. The password
is either the `GITLAB_ROOT_PASSWORD` you set, or the auto-generated one from the first boot:

```bash
docker compose exec gitlab cat /etc/gitlab/initial_root_password
```

> The auto-generated password file is deleted 24 hours after the first boot. If you missed it,
> reset the password with:
> `docker compose exec gitlab gitlab-rake "gitlab:password:reset[root]"`

### 5. View Logs

```bash
docker compose logs -f gitlab
```

### 6. Stop GitLab

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have GitLab start automatically, add `restart: unless-stopped` to the
> service.

## Configuration

### Environment Variables

| Variable               | Required | Description                                                                        |
| ---------------------- | -------- | ---------------------------------------------------------------------------------- |
| `GITLAB_VERSION`       | ❌       | Exact GitLab CE version (defaults to `latest`)                                     |
| `GITLAB_EXTERNAL_URL`  | ❌       | Externally reachable URL (default: `http://localhost`)                             |
| `GITLAB_HTTP_PORT`     | ❌       | Host port for HTTP (default: `80`)                                                 |
| `GITLAB_HTTPS_PORT`    | ❌       | Host port for HTTPS (default: `443`)                                               |
| `GITLAB_SSH_PORT`      | ❌       | Host port for SSH — shown in SSH clone URLs (default: `22`)                        |
| `GITLAB_ROOT_PASSWORD` | ❌       | Initial `root` password, applied on first boot only (default: auto-generated)      |
| `TZ`                   | ❌       | Container timezone (default: `UTC`)                                                |

Any other GitLab setting can be added to the `GITLAB_OMNIBUS_CONFIG` block in
`docker-compose.yml` (one `gitlab.rb` line each). All settings are documented in the
[official GitLab configuration reference](https://docs.gitlab.com/omnibus/settings/configuration/).

### Volumes

| Volume          | Container path | Purpose                              |
| --------------- | -------------- | ------------------------------------ |
| `gitlab_config` | `/etc/gitlab`  | GitLab configuration (`gitlab.rb`)   |
| `gitlab_logs`   | `/var/log/gitlab` | Logs                              |
| `gitlab_data`   | `/var/opt/gitlab` | Application data, repos, databases |

### Ports

| Port | Purpose                  |
| ---- | ------------------------ |
| 80   | HTTP web UI              |
| 443  | HTTPS web UI             |
| 22   | Git over SSH             |

## Updating

1. Back up the instance (see the [official backup guide](https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html)).
2. Bump `GITLAB_VERSION` in `.env` to the next release (e.g. `19.3.0-ce.0`).
3. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Set `GITLAB_VERSION` to the exact release you want to run
- [ ] Set `GITLAB_EXTERNAL_URL` to a real, reachable hostname (not `localhost`)
- [ ] Set a strong `GITLAB_ROOT_PASSWORD` (or reset `root` after first boot)
- [ ] Configure SMTP so GitLab can send email (no MTA is bundled with the image)
- [ ] Terminate TLS with a reverse proxy (e.g. Caddy, Nginx, Traefik) and use `https://` in `GITLAB_EXTERNAL_URL`
- [ ] Set `gitlab_rails['gitlab_shell_ssh_port']` (via `GITLAB_SSH_PORT`) to match the port reachable from outside
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block (GitLab recommends at least 4GB of RAM)
- [ ] Back up the three volumes (or bind mounts) — config, logs, and data
- [ ] Review the [official backup and restore docs](https://docs.gitlab.com/ee/administration/backup_restore/)
