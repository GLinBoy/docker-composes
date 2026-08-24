# Contributing to docker-composes

Thank you for contributing! This repository is a collection of production-oriented Docker Compose
files. To keep every file consistent, maintainable, and deployment-ready, all contributions must
follow the conventions below.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Repository Structure](#repository-structure)
- [Docker Compose Conventions](#docker-compose-conventions)
  - [1. File Structure & Top-Level Order](#1-file-structure--top-level-order)
  - [2. Service Definition Order](#2-service-definition-order)
  - [3. Healthchecks](#3-healthchecks)
  - [4. Image Versioning](#4-image-versioning)
  - [5. Naming Conventions](#5-naming-conventions)
  - [6. Environment Variables & Secrets](#6-environment-variables--secrets)
  - [7. Volumes & Networks](#7-volumes--networks)
  - [8. Resource Limits](#8-resource-limits)
  - [9. Comment Standards](#9-comment-standards)
  - [10. .env.example](#10-envexample)
- [Adding a New Stack](#adding-a-new-stack)
- [Modifying an Existing Stack](#modifying-an-existing-stack)
- [Pull Request Process](#pull-request-process)
- [Quick Reference Checklist](#quick-reference-checklist)

---

## Getting Started

1. Fork the repository and create a branch from `main`:
   ```bash
   git checkout -b feat/add-redis-stack
   # or
   git checkout -b fix/elk-healthcheck
   ```
2. Make your changes following the conventions in this document.
3. Test your compose file locally before opening a PR (see [Testing Locally](#testing-locally)).
4. Open a Pull Request — the PR template checklist will guide you through the review.

---

## Repository Structure

Each stack lives in its own folder named after the technology:

```
docker-composes/
├── elk/
│   ├── docker-compose.yml
│   ├── logstash.conf
│   ├── .env.example
│   └── README.md
├── postgres/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
└── ...
```

**Every folder must contain at minimum:**

| File                 | Required | Purpose                                               |
| -------------------- | -------- | ----------------------------------------------------- |
| `docker-compose.yml` | ✅       | The compose definition                                |
| `.env.example`       | ✅       | Documents all required env variables (no real values) |
| `README.md`          | ✅       | Local usage, verification steps, server checklist     |

---

## Docker Compose Conventions

### 1. File Structure & Top-Level Order

Every `docker-compose.yml` must begin with a `name` field and follow this top-level key order:

```yaml
name: <project-name> # 1. Always first — lowercase, hyphenated (e.g. elk, my-stack)

services: ... # 2. Service definitions
volumes: ... # 3. Named volumes (omit section if none)
networks: ... # 4. Custom networks (omit section if none)
configs: ... # 5. Configs (omit section if none)
secrets: ... # 6. Secrets (omit section if none)
```

> ⚠️ The legacy `version:` field must **not** be included — it is deprecated since Compose v2.

---

### 2. Service Definition Order

Keys inside every service block must appear in this order:

```yaml
services:
  my-service:
    image: # 1. Image — ${VAR:-image:latest} (exact version only in .env / .env.example)
    container_name: # 2. Explicit container name
    restart: # 3. Restart policy
    depends_on: # 4. Service dependencies (with condition:)
    environment: # 5. Environment variables (or env_file:)
    volumes: # 6. Volume mounts
    ports: # 7. Port mappings
    networks: # 8. Network membership
    healthcheck: # 9. Health check — always required
    labels: # 10. Labels (if any)
    deploy: # 11. Resource limits (commented out for local, enabled on server)
```

---

### 3. Healthchecks

**Every service must define a `healthcheck`.** All five fields are required:

```yaml
healthcheck:
  test: [...]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 30s # set based on realistic startup time of the service
```

Use the appropriate test command per service type:

```yaml
# HTTP/API services (web apps, Kibana, etc.)
test: ["CMD-SHELL", "curl -sf http://localhost:<port>/health || exit 1"]

# TCP port check (message brokers, custom services)
test: ["CMD-SHELL", "nc -z localhost <port> || exit 1"]

# PostgreSQL
test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]

# MySQL / MariaDB
test: ["CMD-SHELL", "mysqladmin ping -h localhost -u$${MYSQL_USER} -p$${MYSQL_PASSWORD}"]

# Redis
test: ["CMD", "redis-cli", "ping"]

# MongoDB
test: ["CMD-SHELL", "mongosh --eval 'db.runCommand({ ping: 1 })' --quiet"]

# RabbitMQ
test: ["CMD", "rabbitmq-diagnostics", "ping"]
```

---

### 4. Image Versioning

**All image versions are read from env variables** in `.env.example` / `.env` and referenced
in compose with a `latest` fallback default. Never hardcode a version tag and never use an
exact-pinned fallback default inside `docker-compose.yml`.

```yaml
# ✅ Correct — app image read from env, defaults to latest in compose
image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-latest}

# ✅ Correct — dependency image read from env, also defaults to latest in compose
image: ${DATABASE_IMAGE:-postgres:latest}
image: ${REDIS_IMAGE:-redis:latest}
image: ${PROXY_IMAGE:-nginx:latest}

# .env.example / .env must contain the exact version to deploy (never latest)
# IMMICH_VERSION=v3.1.0
# DATABASE_IMAGE=postgres:18.4-alpine3.23

# ❌ Wrong — no version variable, or an exact-pinned fallback default
image: postgres:latest
image: redis
image: nginx:latest
image: ${DATABASE_IMAGE:-postgres:18.4-alpine3.23}
```

- **Prefer Alpine or slim variants** when available — they are smaller and have a reduced attack surface.
- Use the format `name:MAJOR.MINOR-alpine` or `name:MAJOR.MINOR.PATCH-alpine` in `.env.example` / `.env`.
- To update an app or dependency, bump the exact value in `.env` and re-run
  `docker compose up -d` — no compose file changes required.

---

### 5. Naming Conventions

| Field              | Convention                               | Example           |
| ------------------ | ---------------------------------------- | ----------------- |
| `name` (top-level) | lowercase, hyphenated                    | `my-stack`        |
| `container_name`   | lowercase, hyphenated                    | `my-stack-db`     |
| Volume names       | lowercase, underscore-separated          | `postgres_data`   |
| Network names      | lowercase, hyphenated, suffix `-network` | `backend-network` |
| Folder name        | lowercase, hyphenated, matches `name`    | `my-stack/`       |

---

### 6. Environment Variables & Secrets

- **Never hardcode secrets** (passwords, tokens, API keys) in `docker-compose.yml`.
- Reference all secrets via `${VARIABLE}` and define them in a `.env` file (not committed).
- Always provide a `.env.example` with all variable names documented but **no real values**.

```yaml
# ✅ Correct
environment:
  - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
  - APP_SECRET=${APP_SECRET}

# ❌ Wrong — never commit real secrets
environment:
  - POSTGRES_PASSWORD=supersecret123
```

---

### 7. Volumes & Networks

- Always declare named volumes at the top level — **never use anonymous volumes**.
- Always declare custom networks at the top level — **never rely on the default network**.
- Include a `# SERVER:` comment with the bind-mount alternative for production.

```yaml
volumes:
  postgres_data:
    driver: local
    # SERVER: Use a bind mount for easier backup control:
    # driver_opts:
    #   type: none
    #   o: bind
    #   device: /data/postgres

networks:
  backend-network:
    driver: bridge
```

---

### 8. Resource Limits

Include a commented-out `deploy.resources` block on every service to guide server configuration:

```yaml
services:
  my-service:
    image: ...
    # SERVER: Uncomment and tune before deploying to production
    # deploy:
    #   resources:
    #     limits:
    #       cpus: '1.0'
    #       memory: 512M
    #     reservations:
    #       cpus: '0.25'
    #       memory: 256M
```

---

### 9. Comment Standards

Use three comment types consistently:

```yaml
# Plain comment — general explanation of a non-obvious setting

# LOCAL: context or workaround that only applies when running locally
# Example: # LOCAL: Use host.docker.internal instead of localhost on Docker Desktop (Mac/Windows)

# SERVER: action that MUST be taken before deploying to a production server
# Example: # SERVER: Replace changeme with a strong password — use: openssl rand -hex 32
```

> Every configuration that is intentionally weakened for local development (e.g. security disabled,
> default passwords, exposed ports) **must** have a `# SERVER:` comment explaining what to change.

---

### 10. .env.example

Every compose folder must contain a `.env.example` file:

- List **all** environment variables referenced in `docker-compose.yml`
- Provide descriptive comments for each variable
- **No real values** — empty or example-only values

```bash
# .env.example
# Copy this file to .env and fill in all values before running docker compose up
# Never commit .env to version control — it is listed in .gitignore

# --- Database ---
POSTGRES_USER=           # e.g. myapp
POSTGRES_PASSWORD=       # generate with: openssl rand -hex 32
POSTGRES_DB=             # e.g. myapp_db

# --- Application ---
APP_SECRET_KEY=          # generate with: openssl rand -hex 64
APP_PORT=8080
```

---

## Adding a New Stack

1. Create a new folder named after the technology (lowercase, hyphenated):
   ```bash
   mkdir my-stack
   ```
2. Add the required files:
   - `docker-compose.yml` — following all conventions above
   - `.env.example` — all variables documented
   - `README.md` — covering local usage, service verification, and server checklist
3. Test locally:
   ```bash
   cd my-stack/
   cp .env.example .env   # fill in values
   docker compose up -d
   docker compose ps      # all services should reach "healthy"
   docker compose down -v
   ```
4. Open a Pull Request.

---

## Modifying an Existing Stack

1. Update the image version to the latest stable release (prefer Alpine).
2. Ensure all conventions are still met after your change.
3. Update the `README.md` if any usage steps changed.
4. Test locally — bring the stack up, verify all health checks pass, bring it down.

---

## Testing Locally

Before opening a PR, run the following:

```bash
# 1. Start the stack
docker compose up -d

# 2. Wait for all services to become healthy (may take 1-3 minutes)
docker compose ps

# 3. Verify all services are healthy (not "starting" or "unhealthy")
docker compose ps --format "table {{.Name}}\t{{.Status}}"

# 4. Tear down cleanly
docker compose down -v
```

All services must show `healthy` before the PR is opened.

---

## Pull Request Process

1. Ensure your branch is up to date with `main`.
2. Fill in the **PR template checklist** — every item must be checked or explicitly marked N/A with a reason.
3. PRs without a passing local test are not merged.
4. A maintainer will review and may request changes — please address all comments before re-requesting review.

---

## Quick Reference Checklist

Use this as a final check before opening your PR:

```
File & Structure
[ ] docker-compose.yml present
[ ] .env.example present with all variables documented
[ ] README.md present and up to date
[ ] No version: field at top of file
[ ] name: field present and lowercase-hyphenated

Services
[ ] container_name: defined on every service
[ ] image: read from ${VAR} with a `latest` fallback default (exact version only in .env / .env.example)
[ ] Alpine/slim image used where available
[ ] restart: policy defined on every service
[ ] Service keys in correct order (image → container_name → restart → depends_on → environment → volumes → ports → networks → healthcheck)

Healthchecks
[ ] healthcheck: defined on every service
[ ] All 5 fields present: test, interval, timeout, retries, start_period

Networking & Volumes
[ ] Named volumes declared at top level (no anonymous volumes)
[ ] Custom network declared at top level
[ ] No reliance on the default Docker network

Security
[ ] No hardcoded secrets or passwords
[ ] All secrets use ${VARIABLE} references
[ ] SERVER: comments present for every locally-disabled security feature

Comments
[ ] SERVER: comments on all production-required changes
[ ] LOCAL: comments on any local-only workarounds
[ ] deploy.resources block present (commented out) on every service
```
