# changedetection.io

[changedetection.io](https://changedetection.io) is a self-hosted website change detection and
notification service. It watches web pages for updates (price drops, restock alerts, content edits,
JSON API changes, and more) and notifies you via Discord, Email, Slack, Telegram, webhook, and many
other channels (powered by [Apprise](https://github.com/caronc/apprise)).

This stack runs the app (`ghcr.io/dgtlmoon/changedetection.io`) together with the recommended
**sockpuppetbrowser** Chrome/JS fetcher, so JS-rendered pages, Visual Selector, and screenshots work
out of the box.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if you need to change the port, timezone, or `BASE_URL`. The app image is pinned to
`ghcr.io/dgtlmoon/changedetection.io:0.55.8` by default — bump `CHANGEDETECTION_IMAGE` to update.

### 2. Start changedetection.io

```bash
docker compose up -d
```

The `changedetection` service waits for the `browser-sockpuppet-chrome` service to become healthy
before starting (it is required by the default `PLAYWRIGHT_DRIVER_URL`).

### 3. Verify changedetection.io is Running

```bash
docker compose ps
```

Both services should show as "healthy". The app healthcheck uses Python `urllib` against the web UI,
because the image is `python:3.11-slim` and ships without `curl` or `wget`.

### 4. Open the Web UI

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5000/
# Expected: 200
```

Then browse to <http://localhost:5000> and add your first watch.

### 5. Stop changedetection.io

```bash
docker compose down
# Remove the named volume too:
docker compose down -v
```

## Configuration

### Environment Variables

| Variable                | Required | Description                                                           |
| ----------------------- | -------- | --------------------------------------------------------------------- |
| `CHANGEDETECTION_IMAGE` | ❌       | App image tag (default `...:0.55.8`)                                  |
| `SOCKPUPPET_IMAGE`      | ❌       | Chrome/JS fetcher image (default `...:0.0.3`)                         |
| `CHANGEDETECTION_PORT`  | ❌       | Host port for the web UI (default `5000`)                             |
| `BASE_URL`              | ❌       | Public base URL, used in notification links (no trailing slash)       |
| `PLAYWRIGHT_DRIVER_URL` | ❌       | Chrome/JS fetcher URL (default `ws://browser-sockpuppet-chrome:3000`) |
| `FETCH_WORKERS`         | ❌       | Number of parallel fetchers (default `10`)                            |
| `LOGGER_LEVEL`          | ❌       | Log level: TRACE/DEBUG/INFO/SUCCESS/WARNING/ERROR/CRITICAL            |
| `CHANGEDETECTION_TZ`    | ❌       | Container timezone (default `UTC`)                                    |

Browser tunables: `SCREEN_WIDTH`, `SCREEN_HEIGHT`, `SCREEN_DEPTH`, `MAX_CONCURRENT_CHROME_PROCESSES`.

### Volumes

| Volume                            | Purpose                                        |
| --------------------------------- | ---------------------------------------------- |
| `changedetection-data:/datastore` | All watches, settings, and notification config |

### Ports

| Port | Service      | Access               |
| ---- | ------------ | -------------------- |
| 5000 | Web UI + API | localhost by default |

The browser service is **not** exposed on the host — it is only reachable by the app on the
`changedetection-network`.

## Usage Notes

- **JS rendering**: Enabled by default via `PLAYWRIGHT_DRIVER_URL`. To disable (plain HTTP fetching
  only), set `PLAYWRIGHT_DRIVER_URL=` (empty) in `.env`.
- **Notifications**: Set notification URLs per-watch in the UI (e.g. `discord://...`,
  `telegram://...`, `mailto://...`) — see the
  [Apprise list](https://github.com/caronc/apprise#popular-notification-services).
- **Reverse proxy**: Set `BASE_URL` to your public URL and, if proxying, read
  [Running behind a reverse proxy](https://github.com/dgtlmoon/changedetection.io/wiki/Running-changedetection.io-behind-a-reverse-proxy).

## Production Considerations

### 1. Bind Mount for Data

Uncomment the bind mount in `docker-compose.yml` for easier backup control:

```yaml
volumes:
  - /data/changedetection:/datastore
```

### 2. Resource Limits

Uncomment and tune the `deploy.resources` blocks in `docker-compose.yml` — the browser service
(Chrome) is the biggest consumer of CPU and RAM.

### 3. Security

- Only expose `5000` to trusted networks (or bind to `127.0.0.1` behind a reverse proxy).
- The browser service runs with `cap_add: SYS_ADMIN` (required by Chrome). Upstream also recommends
  a custom `seccomp` profile (`chrome.json`) — see the
  [sockpuppetbrowser README](https://github.com/dgtlmoon/sockpuppetbrowser?tab=readme-ov-file#how-to-run).
- If sites block headless Chrome, enable `CHROME_HEADFUL=true` on the browser service.

### 4. Updates

```bash
docker compose pull && docker compose up -d
```

Bump the exact image values in `.env` to pin a different release.

## Troubleshooting

### changedetection stays "unhealthy"

The app needs a few seconds to initialise its datastore on first start. Check the logs:

```bash
docker compose logs changedetection
```

### JS-rendered watches fail

Confirm the browser is healthy and reachable:

```bash
docker compose ps
docker compose logs browser-sockpuppet-chrome
```
