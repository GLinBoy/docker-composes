# MailHog

[MailHog](https://github.com/mailhog/MailHog) is an email testing tool for developers. It
runs a fake SMTP server that captures outgoing email, and provides a web UI plus a JSON API
to view messages — no real mail server required.

This stack runs a single MailHog container with an in-memory message store, ideal for local
development. Configure your application to send email to port `1025` and watch it arrive in
the web UI at port `8025`.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

No secrets are required. Optionally change:

- `MAILHOG_SMTP_PORT` - the host port for the SMTP server (default `1025`)
- `MAILHOG_UI_PORT` - the host port for the web UI (default `8025`)
- `MAILHOG_VERSION` - the exact MailHog version to run (defaults to `latest` when unset)

### 2. Start MailHog

```bash
docker compose up -d
```

### 3. Verify MailHog is Running

```bash
docker compose ps
```

The service should show as "healthy".

### 4. Point Your Application at MailHog

Configure your app to send SMTP mail to `localhost:1025` (no authentication). For example,
in a PHP app:

```ini
sendmail_path = /usr/sbin/sendmail -S localhost:1025
```

or set your SMTP host to `localhost` and port to `1025`.

### 5. View Captured Email

Open http://localhost:8025 to see all captured messages in the web UI. Messages can also be
retrieved via the HTTP API, e.g.:

```bash
curl http://localhost:8025/api/v2/messages
```

### 6. View Logs

```bash
docker compose logs -f mailhog
```

### 7. Stop MailHog

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have MailHog start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable              | Required | Description                                              |
| --------------------- | -------- | -------------------------------------------------------- |
| `MAILHOG_VERSION`     | ❌       | Exact MailHog version (defaults to `latest` when unset)  |
| `MAILHOG_SMTP_PORT`   | ❌       | Host port for the SMTP server (default: `1025`)          |
| `MAILHOG_UI_PORT`     | ❌       | Host port for the web UI / HTTP API (default: `8025`)    |

### Ports

| Port | Purpose                       |
| ---- | ----------------------------- |
| 1025 | SMTP server (app sends here)  |
| 8025 | Web UI and JSON API           |

### Storage

Messages are stored **in memory** by default and are lost when the container restarts.
For persistence, MailHog supports MongoDB or file-based storage — see the
[storage documentation](https://github.com/mailhog/MailHog/blob/master/docs/CONFIG.md).

## Updating

1. Bump `MAILHOG_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

MailHog is a development/testing tool — it should **not** be exposed to the public internet:

- [ ] Keep MailHog on a local network or behind a reverse proxy with authentication
- [ ] Do not expose ports 1025/8025 to the public internet
- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Optional: configure MongoDB or file-based storage if you need message persistence
