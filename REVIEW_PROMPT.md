# Docker Compose AI Review Prompt

This file contains ready-to-use prompts for asking an AI assistant to review
or fix a Docker Compose file according to the conventions defined in `CONTRIBUTING.md`.

Copy the relevant prompt, paste it into your AI assistant, and attach (or paste)
the target `docker-compose.yml` content.

---

## Prompt 1 — Full Review (read-only, no changes)

Use this when you want a detailed audit report before deciding what to fix.

```
You are a Docker Compose expert. Review the docker-compose.yml file I am providing
and audit it strictly against the following conventions. Do NOT rewrite the file yet —
only produce a structured report.

## Conventions to check

### File Structure
- No deprecated `version:` field at the top
- `name:` field is present, lowercase, and hyphenated
- Top-level key order: name → services → volumes → networks → configs → secrets

### Per-Service Rules
Check every service in the file for the following, and report any violation:

1. `image:` is pinned to an exact version tag — no "latest", no bare image name
2. Alpine or slim variant is used where one is available
3. `container_name:` is explicitly defined and lowercase-hyphenated
4. `restart:` policy is defined (recommended: unless-stopped)
5. `depends_on:` uses condition: (service_healthy or service_started) — not bare depends_on
6. `healthcheck:` is present with all 5 fields: test, interval, timeout, retries, start_period
7. No hardcoded secrets or passwords — all sensitive values use ${VARIABLE} references
8. Service keys appear in this order:
   image → container_name → restart → depends_on → environment → volumes → ports → networks → healthcheck → labels → deploy
9. A commented-out `deploy.resources` block is present for server guidance

### Volumes & Networks
- All volumes are named and declared at the top level (no anonymous volumes)
- All networks are declared at the top level (no default network reliance)
- Named volumes have a `# SERVER:` comment with bind-mount alternative

### Comments
- Every locally-disabled security feature has a `# SERVER:` comment
- Every local-only workaround has a `# LOCAL:` comment

### Companion Files
- Note if `.env.example` or `README.md` are missing from the folder (cannot verify from compose alone, just flag as a reminder)

## Output format

Produce your report in this structure:

### ✅ Passing
List every rule that is correctly followed.

### ❌ Violations
For each violation, state:
- Rule broken
- Service or field affected
- What needs to change

### ⚠️ Recommendations
Optional improvements that are not strict violations but would improve quality.

### Summary
One-paragraph summary of overall quality and priority fixes.
```

---

## Prompt 2 — Full Review + Fix (rewrites the file)

Use this when you want the AI to both audit and produce a corrected version.

```
You are a Docker Compose expert. Review the docker-compose.yml file I am providing
and rewrite it to fully comply with the conventions below. 

After the fixed file, include a short changelog listing every change made and why.
Do not change any functional behaviour — only fix structure, naming, missing fields,
and convention violations. Keep all existing # SERVER: and # LOCAL: comments, and
add new ones wherever a locally-disabled feature needs server-side action.

## Conventions to enforce

### File Structure
- Remove deprecated `version:` field if present
- Add `name:` field at the top — lowercase, hyphenated, matching the folder name
- Top-level key order: name → services → volumes → networks → configs → secrets

### Per-Service Rules — apply to every service

1. Pin `image:` to the latest stable exact version tag
   - Prefer Alpine or slim variant where available
   - Never use "latest" or a bare image name
2. Add `container_name:` if missing — lowercase-hyphenated
3. Add `restart: unless-stopped` if missing
4. Convert bare `depends_on:` to use `condition: service_healthy` (or service_started
   if the dependency has no healthcheck)
5. Add `healthcheck:` if missing — use the appropriate test for the service type:
   - HTTP services: curl -sf http://localhost:<port>/health || exit 1
   - PostgreSQL: pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}
   - Redis: redis-cli ping
   - TCP services: nc -z localhost <port> || exit 1
   All healthchecks must include: test, interval (30s), timeout (10s), retries (5),
   start_period (adjust per realistic startup time)
6. Replace any hardcoded secrets with ${VARIABLE} references and note them in the changelog
7. Reorder service keys to: image → container_name → restart → depends_on →
   environment → volumes → ports → networks → healthcheck → labels → deploy
8. Add a commented-out deploy.resources block if missing:
   # SERVER: Uncomment and tune before deploying to production
   # deploy:
   #   resources:
   #     limits:
   #       cpus: '1.0'
   #       memory: 512M
   #     reservations:
   #       cpus: '0.25'
   #       memory: 256M

### Volumes & Networks
- Convert any anonymous volumes to named volumes declared at the top level
- Declare all networks at the top level
- Add a `# SERVER:` bind-mount comment block to each named volume

### Comment Standards
- Add `# SERVER:` comments on every setting that must change for production
- Add `# LOCAL:` comments on every local-only workaround

## Output format

1. The complete corrected docker-compose.yml (full file, ready to copy-paste)
2. A changelog section:
   ### Changelog
   - [service/field] What was changed and why
```

---

## Prompt 3 — Quick Checklist Only

Use this for a fast pass when you just want a yes/no checklist, not a detailed report.

```
Review this docker-compose.yml against the checklist below.
For each item, respond with ✅ (pass), ❌ (fail — state why), or N/A.

Checklist:
[ ] No version: field
[ ] name: field present and lowercase-hyphenated
[ ] Every service has container_name:
[ ] Every image is pinned to an exact version (no "latest")
[ ] Alpine/slim image used where available
[ ] Every service has restart: policy
[ ] depends_on uses condition: (not bare)
[ ] Every service has healthcheck: with all 5 fields
[ ] No hardcoded secrets or passwords
[ ] All ${VARIABLE} references documented (remind me to check .env.example)
[ ] Named volumes declared at top level
[ ] Custom network declared at top level
[ ] SERVER: comments present for locally-disabled features
[ ] deploy.resources block present (commented) on every service
[ ] Service keys in correct order
```

---

## Prompt 4 — New Stack Scaffold

Use this when starting a brand new docker-compose.yml from scratch.

```
Generate a production-ready docker-compose.yml for [TECHNOLOGY/STACK NAME].

Follow these conventions strictly:

- No version: field
- name: field at top, lowercase-hyphenated
- Top-level order: name → services → volumes → networks
- Use the latest stable Alpine or slim image for every service
- Every service must have:
  - container_name: (lowercase-hyphenated)
  - restart: unless-stopped
  - healthcheck: with all 5 fields (test, interval, timeout, retries, start_period)
  - depends_on: with condition: service_healthy where applicable
  - A commented-out deploy.resources block
- No hardcoded secrets — use ${VARIABLE} references
- Named volumes declared at top level with # SERVER: bind-mount comment
- Custom network declared at top level, ending in "-network"
- Add # SERVER: comments on every setting that must change for production
- Add # LOCAL: comments on every local-only workaround

Also generate:
1. A .env.example file with all referenced variables documented (no real values)
2. A brief README.md covering: local usage, per-service verification commands,
   and a server deployment checklist
```

---

## Tips for Best Results

- **Paste the full file** — partial content leads to incomplete reviews.
- **Mention the folder name** so the AI can validate the `name:` field against it.
- **Share `.env.example` too** when using Prompt 2 — the AI can cross-check that all
  `${VARIABLE}` references in the compose are documented there.
- **Iterate** — use Prompt 1 first to see what needs fixing, then Prompt 2 to apply fixes.
- After the AI produces a fixed file, **test it locally** before opening a PR:
  ```bash
  docker compose config   # validates YAML and compose syntax
  docker compose up -d
  docker compose ps       # all services should reach "healthy"
  docker compose down -v
  ```
