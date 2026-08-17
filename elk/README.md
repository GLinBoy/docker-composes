# ELK

[The ELK stack](https://www.elastic.co/what-is/elk-stack) — **Elasticsearch**, **Logstash** and
**Kibana** — is a log aggregation and visualization stack. Elasticsearch stores and indexes the
logs, Logstash ingests and processes them, and Kibana provides the web UI to explore them.

This stack runs Elasticsearch **9.x** in single-node mode (`discovery.type=single-node`), ideal for
local development and small deployments. Logstash accepts **GELF** (Docker logging driver),
**Beats** (Filebeat/Metricbeat) and **TCP/JSON** (Spring Boot via logstash-logback) input, and
routes each source to its own dated index.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `XPACK_SECURITY_ENCRYPTIONKEY` / `XPACK_REPORTING_ENCRYPTIONKEY` /
  `XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY` — each must be at least 32 chars. The `.env.example`
  ships placeholder values; generate real ones with `openssl rand -hex 32` (once per key).

Optionally change:

- `ELK_VERSION` - the exact Elastic Stack version (defaults to `latest` when unset)
- `ELASTICSEARCH_PORT` / `LOGSTASH_*_PORT` / `KIBANA_PORT` - host port mappings
- `ES_JAVA_OPTS` / `LS_JAVA_OPTS` - JVM heap sizes
- `KIBANA_PUBLICBASEURL` - public URL for Kibana links
- `ELK_TZ` - the timezone (default `UTC`)

### 2. Start the Stack

```bash
docker compose up -d
```

### 3. Verify the Stack is Running

```bash
docker compose ps
```

All services should show as "healthy".

> Elasticsearch takes ~60s, Logstash ~90s, and Kibana ~2 minutes to become healthy. Wait for all
> three before testing.

### 4. Verify the Services

```bash
# Elasticsearch — expect "status": "green" or "yellow"
curl http://localhost:9200/_cluster/health?pretty

# Logstash — expect a JSON node info response
curl http://localhost:9600?pretty

# Kibana — expect "level":"available"
curl http://localhost:5601/api/status | grep -o '"level":"[^"]*"'
```

Or open **http://localhost:5601** in your browser.

### 5. Send a Test Log (GELF)

```bash
echo '{"version":"1.1","host":"test-host","short_message":"Hello ELK!","level":1}' \
  | nc -u -w1 localhost 12201
```

Verify it landed in Elasticsearch:

```bash
curl "http://localhost:9200/docker-logs-*/_search?pretty&q=short_message:Hello"
```

### 6. View Logs

```bash
docker compose logs -f logstash
```

### 7. Stop the Stack

```bash
docker compose down
# Remove data volumes too (full reset):
docker compose down -v
```

> Containers stop when the host restarts (no restart policy is set, per repository convention). To
> have the stack start automatically, uncomment `restart: unless-stopped` on each service.

## Configuration

### Environment Variables

| Variable                                   | Required | Description                                                          |
| ------------------------------------------ | -------- | -------------------------------------------------------------------- |
| `ELK_VERSION`                              | ❌       | Elastic Stack version, pins all three images (default `latest`)      |
| `ELASTICSEARCH_PORT`                       | ❌       | Host port for the ES HTTP API (default: `9200`, loopback only)       |
| `LOGSTASH_GELF_PORT`                       | ❌       | Host port for GELF UDP input (default: `12201`)                      |
| `LOGSTASH_BEATS_PORT`                      | ❌       | Host port for Beats input (default: `5044`)                          |
| `LOGSTASH_TCP_PORT`                        | ❌       | Host port for TCP/JSON input, Spring Boot (default: `5000`)          |
| `KIBANA_PORT`                              | ❌       | Host port for the Kibana web UI (default: `5601`)                    |
| `KIBANA_PUBLICBASEURL`                     | ❌       | Public base URL for Kibana (default: `http://localhost:5601`)        |
| `ES_JAVA_OPTS`                             | ❌       | Elasticsearch JVM heap (default: `-Xms512m -Xmx512m`)                |
| `LS_JAVA_OPTS`                             | ❌       | Logstash JVM heap (default: `-Xms256m -Xmx256m`)                     |
| `XPACK_SECURITY_ENCRYPTIONKEY`             | ✅       | Kibana encryption key, 32+ chars (`openssl rand -hex 32`)            |
| `XPACK_REPORTING_ENCRYPTIONKEY`            | ✅       | Kibana encryption key, 32+ chars (`openssl rand -hex 32`)            |
| `XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY`| ✅       | Kibana encryption key, 32+ chars (`openssl rand -hex 32`)            |
| `ELK_TZ`                                   | ❌       | Container timezone (default: `UTC`)                                  |

### Volumes

| Volume     | Purpose                                            |
| ---------- | -------------------------------------------------- |
| `es_data`  | All Elasticsearch index data (`/usr/share/elasticsearch/data`) |

### Ports

| Port        | Service          | Access                                  |
| ----------- | ---------------- | --------------------------------------- |
| 9200        | Elasticsearch    | loopback only (`127.0.0.1`) by default  |
| 12201/udp   | Logstash (GELF)  | Docker `gelf` logging driver            |
| 5044        | Logstash (Beats) | Filebeat, Metricbeat, etc.              |
| 5000        | Logstash (TCP)   | Spring Boot via logstash-logback        |
| 9600        | Logstash API     | internal only (healthcheck)             |
| 5601        | Kibana           | web UI                                  |

## Sending Logs

### Docker containers (GELF)

Set the `gelf` logging driver on any container on the same Docker host:

```yaml
services:
  my-app:
    logging:
      driver: gelf
      options:
        gelf-address: "udp://localhost:12201"
```

These land in the `docker-logs-YYYY.MM.dd` index.

### Spring Boot (TCP)

Add the dependency to your Spring Boot project:

**Maven:**
```xml
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>8.0</version>
</dependency>
```

**Gradle:**
```groovy
implementation 'net.logstash.logback:logstash-logback-encoder:8.0'
```

Create `src/main/resources/logback-spring.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/base.xml"/>

    <appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
        <!-- SERVER: Replace localhost with your Logstash server IP/hostname -->
        <destination>localhost:5000</destination>
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <customFields>{"app_name":"my-spring-app","env":"local"}</customFields>
        </encoder>
        <reconnectionDelay>10 seconds</reconnectionDelay>
        <keepAliveDuration>5 minutes</keepAliveDuration>
    </appender>

    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="LOGSTASH"/>
    </root>
</configuration>
```

These land in the `spring-logs-YYYY.MM.dd` index.

### Beats (Filebeat, Metricbeat, etc.)

Point your Beat at `localhost:5044` (the `output.logstash` section). These land in the
`beats-YYYY.MM.dd` index.

## Viewing Logs in Kibana

1. Open **http://localhost:5601**
2. Go to **Management → Stack Management → Data Views**
3. Click **Create data view**
4. Set the index pattern:
   - Docker/GELF logs: `docker-logs-*`
   - Spring Boot logs: `spring-logs-*`
   - Beats: `beats-*`
5. Set the time field to `@timestamp`
6. Go to **Discover** and select your data view

## Updating

1. Bump `ELK_VERSION` in `.env` to the next release (e.g. `9.6.0`).
2. Pull and recreate the stack:

```bash
docker compose pull
docker compose up -d
```

> All three images ship with the same version tag, so one bump updates the whole stack.

## Scaling Up

This compose ships Elasticsearch as a **single node** (`discovery.type=single-node`) to keep local
resource usage low. To run a multi-node cluster, unset the single-node mode and add seed hosts:

```yaml
services:
  elasticsearch:
    environment:
      # Remove or comment out:
      # - discovery.type=single-node
      # Add the other nodes:
      - discovery.seed_hosts=es-node-02
      - cluster.initial_master_nodes=es-node-01,es-node-02
```

Then add a second node as a new service with its own container name and volume:

```yaml
  elasticsearch-2:
    image: docker.elastic.co/elasticsearch/elasticsearch:${ELK_VERSION:-latest}
    container_name: es-node-02
    environment:
      - discovery.seed_hosts=es-node-01
      - cluster.initial_master_nodes=es-node-01,es-node-02
      - node.name=es-node-02
    volumes:
      - es_data_2:/usr/share/elasticsearch/data
    networks:
      - elk-network
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
```

And declare the extra volume:

```yaml
volumes:
  es_data_2:
    driver: local
```

See the [Elasticsearch cluster discovery docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery.html) for details.

## Troubleshooting

| Symptom                              | Likely Cause                          | Fix                                                        |
| ------------------------------------ | ------------------------------------- | ---------------------------------------------------------- |
| ES exits immediately                 | Insufficient memory                   | Lower `ES_JAVA_OPTS` to `-Xms256m -Xmx256m`                |
| `vm.max_map_count` error             | Linux kernel setting too low          | `sudo sysctl -w vm.max_map_count=262144`                   |
| Kibana stuck on loading screen       | ES not ready yet                      | Wait 2–3 min and refresh                                   |
| Logstash not healthy                 | Pipeline config syntax error          | `docker compose logs logstash` to inspect                  |
| No logs appearing in Kibana          | Wrong index pattern                   | `curl http://localhost:9200/_cat/indices?v` to list indices|
| Kibana encryption key error          | Key shorter than 32 characters        | Ensure all `XPACK_*_ENCRYPTIONKEY` values are 32+ chars    |

### Linux: virtual memory map count

Elasticsearch requires a higher `vm.max_map_count`:

```bash
sudo sysctl -w vm.max_map_count=262144
```

To persist it across reboots, add `vm.max_map_count=262144` to `/etc/sysctl.conf`.

## Server Checklist

Before deploying to a production server:

- [ ] Generate real 32-byte encryption keys for Kibana and put them in `.env`:
      `openssl rand -hex 32` (run 3 times, one per key)
- [ ] Set `ES_JAVA_OPTS` to half of the server's RAM (e.g. `-Xms4g -Xmx4g` for 8 GB)
- [ ] Enable security on Elasticsearch: set `xpack.security.enabled=true` and
      `xpack.security.http.ssl.enabled=true` in `docker-compose.yml`
- [ ] Generate a Kibana service account token and use `ELASTICSEARCH_SERVICEACCOUNTTOKEN`
      instead of credentials (see the elasticsearch service comment in `docker-compose.yml`)
- [ ] Set `KIBANA_PUBLICBASEURL` to your actual domain
- [ ] Place Kibana behind a reverse proxy (Caddy/Nginx/Traefik) with HTTPS/TLS termination and
      remove the Kibana `ports` block
- [ ] Bind Logstash ports to `127.0.0.1` (or a specific interface) — never expose them publicly
- [ ] Keep Elasticsearch bound to loopback only (`127.0.0.1:9200:9200`)
- [ ] Configure Elasticsearch snapshot/backup for the `es_data` volume
- [ ] Uncomment and tune the `deploy.resources` block on each service
- [ ] Uncomment `restart: unless-stopped` on each service if you want auto-start after reboots
- [ ] Update `<destination>` in `logback-spring.xml` from `localhost` to your server hostname

## Resources

- [Elastic Stack documentation](https://www.elastic.co/docs)
- [Elasticsearch discovery and cluster formation](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery.html)
- [GELF Docker logging driver](https://docs.docker.com/engine/logging/drivers/gelf/)
- [logstash-logback-encoder](https://github.com/logfellow/logstash-logback-encoder)
