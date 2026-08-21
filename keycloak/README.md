# Keycloak

[Keycloak](https://www.keycloak.org/) is an open-source identity and access management solution —
SSO, OIDC/SAML federation, user management, MFA, and admin console, all self-hosted.

This stack runs the official [keycloak/keycloak image](https://hub.docker.com/r/keycloak/keycloak)
(tag `26.7.2`) in **development mode** (`start-dev`) so it works out of the box over plain HTTP with
zero certificates. It imports the bundled **sample realm** on first start and persists its data in a
named volume.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

By default the Keycloak **admin** user is `admin` / `admin`. The image is pinned to
`keycloak/keycloak:26.7.2` — bump `KEYCLOAK_VERSION` to update. Change `KEYCLOAK_PORT` if `8080`
collides with another service.

### 2. Start Keycloak

```bash
docker compose up -d
```

### 3. Verify Keycloak is Running

```bash
docker compose ps
```

The `keycloak` service should show as **healthy** (the healthcheck probes `/health/ready` on the
management port `9000`). First boot takes a minute or two.

### 4. Open the Admin Console

Browse to <http://localhost:8080/admin> and sign in with the bootstrap admin user from `.env`
(`admin` / `admin`).

### 5. Stop Keycloak

```bash
docker compose down
# Remove the data volume too:
docker compose down -v
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Keycloak start automatically, add `restart: unless-stopped` to the service.

## Sample Realm (fast setup for your app)

The `realm-config/` folder ships a ready-to-use realm: **`jhipster`**. It is imported **once**, on the
first start, then stored in the database. Same as JHipster's development setup, it gives you
realms, roles, groups, OIDC clients, and a demo user so you can wire your app to OAuth2/OIDC in
minutes.

### Realm details

| Setting           | Value              |
| ----------------- | ------------------ |
| Realm name        | `jhipster`         |
| Realm roles       | `ROLE_ADMIN`, `ROLE_USER` |
| Groups            | `Admins`, `Users`  |
| Access token TTL  | 300 s (5 min)      |
| SSO session max   | 36 000 s (10 h)    |
| Public registration | disabled        |

### Demo user

| Field    | Value               |
| -------- | ------------------- |
| Username | `user`              |
| Password | `123456`            |
| Email    | `user@localhost`    |
| Roles    | `ROLE_USER`, `ROLE_ADMIN` |
| Groups   | `Users`, `Admins`   |

> ⚠️ Demo credentials are for local development only. Change the password in the Admin Console
> (**Users → user → Credentials**) or edit `realm-config/jhipster-realm.json` and re-import before
> exposing the server (see [Production](#production)).

### Pre-configured OIDC clients

The realm includes clients used by JHipster apps — reuse the same values in your own application:

| Client            | Type         | Secret      | Best for                          |
| ----------------- | ------------ | ----------- | --------------------------------- |
| `web_app`         | Public       | —           | SPA / mobile front-end            |
| `internal`        | Confidential | `internal`  | Backend APIs (service accounts)   |
| `admin-cli`       | Public       | —           | Direct Access Grant (password flow) |

### Point your app at Keycloak

```text
Issuer / auth URL : http://localhost:8080/realms/jhipster
Discovery document: http://localhost:8080/realms/jhipster/.well-known/openid-configuration
JWK set            : http://localhost:8080/realms/jhipster/protocol/openid-connect/certs
```

Example application config (Spring Boot / JHipster):

```yaml
spring:
  security:
    oauth2:
      client:
        provider:
          oidc:
            issuer-uri: http://localhost:8080/realms/jhipster
        registration:
          oidc:
            client-id: web_app
            scope: openid,profile,email
```

And the token exchange for testing:

```bash
curl -sf http://localhost:8080/realms/jhipster/protocol/openid-connect/token \
  -d client_id=admin-cli \
  -d grant_type=password \
  -d username=user \
  -d password=123456 \
  --data-urlencode "scope=openid profile email" \
  | python3 -m json.tool
```

### Make it yours

- **Add your own realm/users** — export from the Admin Console or add a JSON file to `realm-config/`:
  every JSON file in that folder is imported on first start.
- **Re-import after editing** — imports only run on an empty database:
  `docker compose down -v && docker compose up -d`.

## Configuration

### Environment Variables

| Variable                   | Required  | Description                                        |
| -------------------------- | --------- | -------------------------------------------------- |
| `KEYCLOAK_VERSION`         | ❌        | Image tag (default `keycloak/keycloak:26.7.2`)      |
| `KEYCLOAK_ADMIN`           | ❌        | Admin console username (default `admin`)           |
| `KEYCLOAK_ADMIN_PASSWORD`  | ❌        | Admin console password (default `admin` — **change for production**) |
| `KEYCLOAK_PORT`            | ❌        | Host port for web UI / auth, mapped to container 8080 (default `8080`) |
| `KEYCLOAK_TZ`              | ❌        | Container timezone (default `UTC`)                 |

### Volumes

| Volume                       | Purpose                                              |
| ---------------------------- | ---------------------------------------------------- |
| `keycloak_data:/opt/keycloak/data` | Persists the embedded H2 database & keys    |
| `./realm-config:/opt/keycloak/data/import` | Realm JSON files imported on first start |

### Ports

| Port | Service  | Access               |
| ---- | -------- | -------------------- |
| 8080 | Keycloak | Web UI + OIDC (HTTP) |
| 9000 | Keycloak | Management / health (container-internal only) |

## Updating

1. Bump `KEYCLOAK_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Production

`start-dev` is **only for development** — Keycloak prints a warning, and it disables several security
features. Before exposing it publicly:

### 1. Run production mode

Switch the command from `start-dev` to `start` — this requires a hostname and TLS certificates:

```bash
# .env
KC_HOSTNAME=idp.example.com
KC_HTTPS_CERTIFICATE_FILE=/certs/kc.fullchain.pem
KC_HTTPS_CERTIFICATE_KEY_FILE=/certs/kc.key
```

```yaml
command: ["start", "--import-realm"]
```

(or terminate TLS with a reverse proxy — Caddy, Traefik, Nginx — and pass `KC_PROXY=headwind`).

### 2. Use a real database

The H2 dev-file DB is not suitable for production. Either mount the bind-mount volume (see
`docker-compose.yml`) and back it up, or point Keycloak at PostgreSQL/MariaDB via `KC_DB`,
`KC_DB_URL`, `KC_DB_USERNAME`, `KC_DB_PASSWORD` (see the [database guide](https://www.keycloak.org/server/db)).

### 3. Strong secrets

```bash
openssl rand -base64 24 | tr -d '\n'   # KEYCLOAK_ADMIN_PASSWORD
openssl rand -hex 32                   # KC_DB_PASSWORD
```

### 4. Resource limits & backups

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. Back up the
`keycloak_data` volume (or bind-mount target) and any custom realm files.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs keycloak
```

Keycloak may still be starting up — first boot runs realm import and key generation. If it keeps
failing, raise `start_period` in `docker-compose.yml`.

### Realm not imported after I changed the JSON

Imports run only on first start against an empty database. Wipe and re-import:

```bash
docker compose down -v && docker compose up -d
```

### Port 8080 already in use

Change `KEYCLOAK_PORT` in `.env` and re-run:

```bash
docker compose up -d
```

### Forgot the admin password

`docker compose down -v` removes **all** data (realm, users, admin). Restart and the bootstrap admin
is recreated from `.env` — realms are re-imported from `realm-config/`.

## Useful Commands

```bash
# View logs
docker compose logs -f keycloak

# Reach the admin console
open http://localhost:8080/admin

# Check health endpoints
curl -s http://localhost:9000/health/ready
curl -s http://localhost:9000/health

# Verify the oidc discovery document
curl -s http://localhost:8080/realms/jhipster/.well-known/openid-configuration
```

## Resources

- [Keycloak website](https://www.keycloak.org/)
- [Keycloak documentation](https://www.keycloak.org/documentation)
- [Keycloak server config reference](https://www.keycloak.org/server/configuration)
- [keycloak image on Docker Hub](https://hub.docker.com/r/keycloak/keycloak)