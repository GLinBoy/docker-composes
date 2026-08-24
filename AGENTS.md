# Guidelines for AI Assistants

This document provides essential guidance for AI assistants contributing to this repository.

## Important

**Before contributing, AI assistants MUST read and follow:**

1. **[CONTRIBUTING.md](CONTRIBUTING.md)** - Complete contribution guidelines, Docker Compose conventions, file structure, healthchecks, security requirements, and testing procedures
2. **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** - Community standards and behavior expectations

## Key Reminders

### Restart Policy

**DO NOT add `restart: unless-stopped`** or any restart policy unless explicitly requested. Containers should stop when the host system restarts to save resources.

### Timezone

**Use `UTC` (UTC+0) by default** everywhere a timezone is required in compose files — the `TZ` environment variable, `PHP_TIMEZONE`, cron schedules, config files, etc. — unless a specific timezone is explicitly requested.

### Image Versioning

Every image version is read from an env variable defined in `.env.example` / `.env` and
referenced in compose with a `latest` fallback default — **never hardcode a version tag and never
use an exact-pinned fallback default inside the compose file**:

```yaml
image: ${IMMICH_VERSION:-ghcr.io/immich-app/immich-server:latest}
image: ${POSTGRES_IMAGE:-postgres:latest}
```

- **`.env.example` / `.env` must contain the exact value to deploy** (never `latest`) — for every
  image, app or dependency:

  ```bash
  IMMICH_VERSION=v3.1.0
  POSTGRES_IMAGE=postgres:18.4-alpine3.23
  ```

- To update any image, bump the exact value in `.env` and re-run `docker compose up -d` — no
  compose file changes required.
- Prefer Alpine or slim variants when available.

### Cluster Services

Services that are designed to run as a cluster (e.g. Cassandra, ScyllaDB, CockroachDB) need
special handling — a single node is not a cluster, but running many by default wastes resources:

- **Default to exactly 2 instances** — one "master" (seed/first node) and one "slave"
  (second node). This keeps the compose file small and the local resource usage low.
- Name the instances explicitly, e.g. `cassandra-0` (master) and `cassandra-1` (slave).
- Every instance needs its own named data volume and container name.
- The **README.md must include a "Scaling Up" section** that explains, step by step, how to
  add more master or slave instances — including the new service block, the new volume, and
  any seed/join-list updates required in `.env` / the compose file.

### File Naming

- Compose folders: lowercase, hyphenated (e.g., `my-service/`)
- Always include: `docker-compose.yml`, `.env.example`, `README.md`

### README Updates

When adding new compose files, add an entry to the root [README.md](README.md) in **alphabetical order** following the existing format:

```markdown
- [Service Name](folder/) ([website](https://example.com))
```

## Quick Reference

For detailed conventions, see [CONTRIBUTING.md](CONTRIBUTING.md) section:

- Docker Compose Conventions (file structure, service order, healthchecks, image versioning, etc.)
- Adding a New Stack
- Testing Locally
- Quick Reference Checklist
