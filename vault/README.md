# Vault

[HashiCorp Vault](https://www.vaultproject.io/) manages secrets — credentials, certificates,
API keys, encryption — with centralized access control and auditing. This stack runs the official
[hashicorp/vault image](https://hub.docker.com/r/hashicorp/vault) (Alpine-based, runs as the
`vault` user with `IPC_LOCK` for mlock) in **dev mode**: the server is auto-unsealed, stores
everything **in memory**, and authenticates with a plain-text root token from `.env`.

> ⚠️ **Dev mode is for local development only.** There is no persistence — every secret is lost
> when the container restarts — and the root token sits in plain text. See
> [Production Considerations](#production-considerations) for the init/unseal setup.

The healthcheck runs `vault status`, which exits 0 only when the server is reachable **and**
unsealed — more meaningful than a plain TCP probe.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `hashicorp/vault:2.0.4` by default. Change `VAULT_PORT` if `8200` collides
with another service. `VAULT_DEV_ROOT_TOKEN_ID` holds the dev root token used to log in.

### 2. Start Vault

```bash
docker compose up -d
```

### 3. Verify Vault is Running

```bash
docker compose ps
```

The `vault` service should show as "healthy", and the Web UI should be up at
`http://localhost:8200/` (sign in with the **Token** method using `VAULT_DEV_ROOT_TOKEN_ID`).

### 4. Store a Secret

```bash
docker compose exec -e VAULT_TOKEN="$(grep '^VAULT_DEV_ROOT_TOKEN_ID=' .env | cut -d= -f2)" vault \
  vault kv put secret/myapp username=admin password=s3cr3t
docker compose exec vault vault kv get secret/myapp
```

(Inside the container `VAULT_ADDR` is already set, so plain `vault ...` commands work.)

### 5. Stop Vault

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have Vault start automatically, add `restart: unless-stopped` to the service.

## Configuration

### Environment Variables

| Variable                  | Required | Description                                                  |
| ------------------------- | -------- | ------------------------------------------------------------ |
| `VAULT_VERSION`           | ❌       | Image tag (default `2.0.4`)                                  |
| `VAULT_PORT`              | ❌       | Host port for API/UI (default `8200`, maps to 8200)          |
| `VAULT_DEV_ROOT_TOKEN_ID` | ❌       | Dev root token (empty = Vault generates one, printed in logs)|

`VAULT_ADDR` (CLI client address) and `VAULT_DEV_LISTEN_ADDRESS` (server bind address) are set in
`docker-compose.yml` and rarely need changing.

### Volumes

None — dev mode stores everything in **memory** on purpose. The image's `/vault/file`,
`/vault/config` and `/vault/logs` directories become relevant only in a production setup (below).

## Production Considerations

### 1. Switch from Dev Mode to a Real Server

Dev mode cannot be used in production. Mount a config file with persistent storage, drop the
`VAULT_DEV_*` variables (so the entrypoint stops adding `-dev*` flags), and initialize/unseal:

`config.hcl`:

```hcl
ui = true

storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1   # SERVER: enable TLS (see below)
}
```

`compose.override.yml`:

```yaml
services:
  vault:
    command: server            # no -dev — entrypoint only adds dev flags automatically
    volumes:
      - ./config.hcl:/vault/config/config.hcl:ro
      - ./file:/vault/file
      - ./logs:/vault/logs
```

Then initialize and unseal once (keep the 5 unseal keys + initial root token safe — e.g. in your
password manager):

```bash
docker compose exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault operator init -key-shares=5 -key-threshold=3
docker compose exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault operator unseal <key-1>
docker compose exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault operator unseal <key-2>
docker compose exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault operator unseal <key-3>
```

Vault must be **unsealed again after every restart** (3 of the 5 keys) — that is by design.

### 2. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` once the server is production-grade.

### 3. TLS

Set `tls_disable = 0` in the listener block and mount certificate/key files into the container;
unseal afterwards with `vault operator unseal`. Fronting with a reverse proxy
([Traefik](../traefik/), [Caddy](../caddy/)) that terminates TLS is a common alternative —
do not publish port `8200` publicly in that case.

### 4. Backup

With file storage, `./file` holds the encrypted vault state — include it (and a copy of your
unseal keys, stored securely elsewhere) in your regular backups.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs vault
```

The healthcheck requires the server to be reachable **and unsealed**. In dev mode it is always
unsealed, so failures mean the server crashed (see the log tail). In a production setup a **sealed**
vault also reports unhealthy until you run `vault operator unseal` — that is the intended signal.

### UI shows 403 / "Permission denied"

Log in with the **Token** method using `VAULT_DEV_ROOT_TOKEN_ID` from `.env`. If you left it empty,
read the generated token from the startup logs:

```bash
docker compose logs vault | grep -A2 'Root Token'
```

### All my secrets disappeared

Expected in dev mode — storage is in-memory. Re-create them, or switch to the file/raft storage
setup in [Production Considerations](#1-switch-from-dev-mode-to-a-real-server).

### Port already in use

Change `VAULT_PORT` in `.env` and re-run `docker compose up -d`.

## Useful Commands

```bash
# View logs (also prints the generated root token when unset)
docker compose logs -f vault

# Check seal/health state
docker compose exec vault vault status

# Shell access (runs as the `vault` user)
docker compose exec vault /bin/sh

# Read/write secrets (dev token from .env)
docker compose exec -e VAULT_TOKEN="$(grep '^VAULT_DEV_ROOT_TOKEN_ID=' .env | cut -d= -f2)" vault \
  vault kv put secret/myapp key=value
docker compose exec vault vault kv get secret/myapp
```

## Resources

- [Vault website](https://www.vaultproject.io/)
- [Vault documentation](https://developer.hashicorp.com/vault/docs)
- [Dev server mode reference](https://developer.hashicorp.com/vault/docs/concepts/dev-server)
- [hashicorp/vault image docs](https://developer.hashicorp.com/vault/docs/platform/docker)
- [hashicorp/vault on Docker Hub](https://hub.docker.com/r/hashicorp/vault)