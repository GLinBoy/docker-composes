# Stirling PDF

[Stirling PDF](https://www.stirlingpdf.com) is a robust, locally hosted web-based PDF manipulation
tool. It offers 50+ operations — split, merge, convert, rotate, compress, add watermarks, OCR
(Tesseract), sign, and more — all through a clean web UI. Files are processed in memory and
discarded after download, so nothing is stored server-side beyond your own volumes.

This stack runs the official `stirlingtools/stirling-pdf` image (Debian slim, ships `curl` for the
healthcheck) with named volumes for OCR data, config, logs, custom files, and pipelines, plus a
custom network.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

The image is pinned to `stirlingtools/stirling-pdf:2.14.3` by default — bump `STIRLING_PDF_IMAGE`
to update. Change `STIRLING_PDF_PORT` if `8080` collides with another service.

### 2. Start Stirling PDF

```bash
docker compose up -d
```

### 3. Verify Stirling PDF is Running

```bash
docker compose ps
```

The `stirling-pdf` service should show as "healthy".

### 4. Access the Web UI

Open `http://localhost:8080`. Because `SECURITY_ENABLELOGIN=true` by default, you'll be asked to
create a login account — the first account created becomes the admin.

### 5. Stop Stirling PDF

```bash
docker compose down
# Remove the named volumes too (deletes all data):
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                    | Required | Description                                                       |
| --------------------------- | -------- | ----------------------------------------------------------------- |
| `STIRLING_PDF_IMAGE`        | ❌       | Image tag (default `stirlingtools/stirling-pdf:2.14.3`)           |
| `STIRLING_PDF_PORT`         | ❌       | Host port for the web UI, mapped to container 8080 (default `8080`) |
| `SECURITY_ENABLELOGIN`      | ❌       | Require login (default `true`)                                    |
| `LANGS`                     | ❌       | OCR languages (default `en_GB`)                                   |
| `SYSTEM_DEFAULTLOCALE`      | ❌       | Default UI locale (default `en-GB`)                               |
| `SYSTEM_GOOGLEVISIBILITY`   | ❌       | Allow search-engine indexing (default `false`)                    |
| `SYSTEM_MAXFILESIZE`        | ❌       | Max PDF upload in MB, 0 = unlimited (default `2000`)              |

### Volumes

| Volume                        | Purpose                                          |
| ----------------------------- | ------------------------------------------------ |
| `tessdata:/usr/share/tessdata` | Tesseract OCR language data                     |
| `configs:/configs`            | App settings                                     |
| `logs:/logs`                  | Log files                                        |
| `custom_files:/customFiles`   | Custom files (templates, static assets)          |
| `pipeline:/pipeline`          | Pipeline definitions for automated workflows     |

### Ports

| Port | Service      | Access              |
| ---- | ------------ | ------------------- |
| 8080 | Stirling PDF | Web UI (TCP)        |

## Updating

Bump `STIRLING_PDF_IMAGE` in `.env` and recreate:

```bash
docker compose pull
docker compose up -d
```

Refer to the [Stirling PDF changelog](https://github.com/Stirling-Tools/Stirling-PDF/releases) for
breaking changes before jumping major versions.

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so Stirling PDF starts automatically on
boot or failure.

### 2. Login

`SECURITY_ENABLELOGIN=true` is recommended when the app is reachable beyond localhost. After the
first login, disable the default settings page access or restrict by network.

### 3. Reverse Proxy

Put Stirling PDF behind one of the reverse-proxy stacks ([Caddy](../caddy/),
[Traefik](../traefik/), [Nginx Proxy Manager](../nginx-proxy-manager/)) for automatic TLS. If you
do, set `SYSTEM_GOOGLEVISIBILITY=false` and enable login.

### 4. Bind Mounts for Data

Uncomment the bind mount driver options in `docker-compose.yml` for simpler backups. Back up
`configs`, `logs`, and `customFiles` regularly.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` block in `docker-compose.yml`. PDF processing (especially
OCR and LibreOffice conversion) is memory-hungry — the shipped example allows up to 4 GB.

## Troubleshooting

### Container stays unhealthy

```bash
docker compose logs stirling-pdf
```

The healthcheck requests `http://localhost:8080/api/v1/info/status`. First boot can take a while
while Tesseract data and configs initialize — raise `start_period` (60s) if needed.

### Login page loops or you can't create an admin

If `SECURITY_ENABLELOGIN=true` and no admin exists yet, the login page itself creates the first
account. If the `configs` volume was pre-populated, remove it and restart to rebuild the user store.

### Port 8080 already in use

Change `STIRLING_PDF_PORT` in `.env` and re-run `docker compose up -d`.

### OCR language not working

Ensure the language tag is in `LANGS` (e.g. `fr_FR`) and that the corresponding Tesseract data is
present in the `tessdata` volume.

## Useful Commands

```bash
# View logs
docker compose logs -f stirling-pdf

# Shell access
docker exec -it stirling-pdf bash

# Check the status API
curl -sf http://localhost:8080/api/v1/info/status

# List OCR languages available in the container
docker exec stirling-pdf ls /usr/share/tessdata
```

## Resources

- [Stirling PDF website](https://www.stirlingpdf.com)
- [Stirling PDF docs](https://docs.stirlingpdf.com/)
- [stirlingtools/stirling-pdf image on Docker Hub](https://hub.docker.com/r/stirlingtools/stirling-pdf)
- [Stirling-Tools/Stirling-PDF on GitHub](https://github.com/Stirling-Tools/Stirling-PDF)
