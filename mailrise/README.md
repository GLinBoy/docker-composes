# Mailrise

[Mailrise](https://github.com/YoRyan/mailrise) is an SMTP server that converts the emails
it receives into [Apprise](https://github.com/caronc/apprise) notifications. It enables
Linux servers, IoT devices, surveillance systems, and other software that can only send
email to reach 60+ notification services — from Telegram and Discord to ntfy, Matrix, and
more.

This stack runs a single Mailrise container. You configure notification targets in a YAML
file, and senders select them by using the recipient address
`<config-name>@mailrise.xyz` (or `<config-name>.<type>@mailrise.xyz` for a specific
notification type).

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

No secrets are required. Optionally change:

- `MAILRISE_PORT` - the host port for the SMTP server (default `8025`)
- `MAILRISE_VERSION` - the exact Mailrise version to run (defaults to `latest` when unset)
- `MAILRISE_DOMAIN` - your public domain, only if you use the Traefik integration

### 2. Configure Notification Targets

```bash
cp mailrise.conf.example mailrise.conf
```

Edit `mailrise.conf` and add at least one Apprise notification target under `configs`. For
example:

```yaml
configs:
  ntfy:
    urls:
      - ntfy://ntfy.sh/some-topic
```

See [Mailrise's configuration reference](https://github.com/YoRyan/mailrise#configuration)
for the full list of options.

### 3. Start Mailrise

```bash
docker compose up -d
```

### 4. Verify Mailrise is Running

```bash
docker compose ps
```

The service should show as "healthy".

### 5. Point Your Application at Mailrise

Configure your app to send SMTP mail to `localhost:8025` (no authentication). For example,
in a PHP app:

```ini
sendmail_path = /usr/sbin/sendmail -S localhost:8025
```

Address the email to a configured recipient, e.g. `ntfy@mailrise.xyz`, and Mailrise will
deliver it to the matching Apprise service.

### 6. View Logs

```bash
docker compose logs -f mailrise
```

### 7. Stop Mailrise

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository
> convention). To have Mailrise start automatically, add `restart: unless-stopped` to each
> service.

## Configuration

### Environment Variables

| Variable            | Required | Description                                                     |
| ------------------- | -------- | --------------------------------------------------------------- |
| `MAILRISE_VERSION`  | ❌       | Exact Mailrise version (defaults to `latest` when unset)        |
| `MAILRISE_PORT`     | ❌       | Host port for the SMTP server (default: `8025`)                 |
| `MAILRISE_DOMAIN`   | ❌       | Public domain for the Traefik TLS certificate (Traefik only)    |

### Volumes

| Volume           | Purpose                                   |
| ---------------- | ----------------------------------------- |
| `./mailrise.conf` | Mailrise configuration (mounted read-only) |

### Ports

| Port | Purpose                     |
| ---- | --------------------------- |
| 8025 | SMTP server (app sends here) |

### Traefik Integration

Mailrise runs as a plaintext SMTP server on port 8025. For TLS-on-connect (port 465), the
compose file includes Traefik TCP router labels that terminate TLS in front of Mailrise.
To use them:

1. Add a `mailsecure` entrypoint (`address: ":465"`) and a `letsencrypt` certificate
   resolver to your Traefik configuration.
2. Set `MAILRISE_DOMAIN` in `.env` to your public domain.
3. Point SMTP clients at `mail.example.com:465` using TLS-on-connect.

## Updating

1. Bump `MAILRISE_VERSION` in `.env` to the next release.
2. Pull and recreate the container:

```bash
docker compose pull
docker compose up -d
```

## Server Checklist

Before deploying to a production server:

- [ ] Add `restart: unless-stopped` if you want auto-start after reboots
- [ ] Uncomment and tune the `deploy.resources` block on the service
- [ ] Enable SMTP authentication and/or TLS in `mailrise.conf` (credentials are sent in
      plaintext otherwise — see the [TLS + Traefik section](https://github.com/YoRyan/mailrise#easy-tls-with-traefik))
- [ ] Set `MAILRISE_DOMAIN` and terminate TLS with Traefik if exposing SMTP publicly
- [ ] Do not expose the SMTP port to the public internet without authentication/TLS
