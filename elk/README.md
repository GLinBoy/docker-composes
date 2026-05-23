# ELK Stack — Docker Compose Setup

A production-oriented ELK (Elasticsearch, Logstash, Kibana) stack using Docker Compose, pinned to version **9.4.1**. Designed to run out-of-the-box locally with clear inline comments guiding every change needed for a production server deployment.

---

## Stack Overview

| Service | Image | Port(s) |
|---|---|---|
| Elasticsearch | `docker.elastic.co/elasticsearch/elasticsearch:9.4.1` | `9200` (internal only) |
| Logstash | `docker.elastic.co/logstash/logstash:9.4.1` | `12201/udp` (GELF), `5044` (Beats), `5000` (TCP/Spring Boot) |
| Kibana | `docker.elastic.co/kibana/kibana:9.4.1` | `5601` |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) >= 24.x
- [Docker Compose](https://docs.docker.com/compose/) >= v2.x (included with Docker Desktop)
- **Linux only:** Increase the virtual memory map limit required by Elasticsearch:

```bash
sudo sysctl -w vm.max_map_count=262144
```

To persist this setting across reboots, add the following to `/etc/sysctl.conf`:

```
vm.max_map_count=262144
```

---

## Files

```
elk/
├── docker-compose.yml   # Main compose file
├── logstash.conf        # Logstash pipeline (GELF + Beats + TCP inputs)
└── README.md            # This file
```

---

## Local Development Usage

### Start the stack

```bash
cd elk/
docker compose up -d
```

### Watch logs during startup

```bash
docker compose logs -f
```

> Elasticsearch takes ~60s, Logstash ~90s, and Kibana ~2 minutes to become healthy. Wait for all three before testing.

### Check all container health statuses

```bash
docker compose ps
```

All services should show `healthy`. If any shows `starting`, wait another minute and re-run.

### Stop the stack (keeps data)

```bash
docker compose down
```

### Full reset (deletes all Elasticsearch data)

```bash
docker compose down -v
```

---

## Verifying the Services

### Elasticsearch

```bash
# Cluster health — expect "status": "green" or "yellow"
curl http://localhost:9200/_cluster/health?pretty

# List all indices
curl http://localhost:9200/_cat/indices?v
```

### Logstash

```bash
# Node info — expect a JSON response
curl http://localhost:9600?pretty

# Check pipeline is running
curl http://localhost:9600/_node/pipelines?pretty
```

### Kibana

```bash
# Status API — expect "level":"available"
curl http://localhost:5601/api/status | grep -o '"level":"[^"]*"'
```

Or open **http://localhost:5601** in your browser.

### All-in-one health check

```bash
echo "=== Elasticsearch ===" && curl -sf http://localhost:9200/_cluster/health?pretty \
  && echo "=== Logstash ===" && curl -sf http://localhost:9600?pretty | head -5 \
  && echo "=== Kibana ===" && curl -sf http://localhost:5601/api/status | grep -o '"level":"[^"]*"'
```

---

## Sending Test Logs

### Via GELF (UDP)

```bash
echo '{"version":"1.1","host":"test-host","short_message":"Hello ELK!","level":1}' \
  | nc -u -w1 localhost 12201
```

Verify in Elasticsearch:

```bash
curl "http://localhost:9200/docker-logs-*/_search?pretty&q=short_message:Hello"
```

### Via Spring Boot (TCP)

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

---

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

---

## Logstash Inputs Summary

| Input | Protocol | Port | Source |
|---|---|---|---|
| GELF | UDP | `12201` | Docker containers via `gelf` logging driver |
| Beats | TCP | `5044` | Filebeat, Metricbeat, etc. |
| Spring Boot | TCP | `5000` | `logstash-logback-encoder` direct TCP appender |

---

## Elasticsearch Index Patterns

| Source | Index Pattern |
|---|---|
| Docker containers | `docker-logs-YYYY.MM.dd` |
| Beats | `beats-YYYY.MM.dd` |
| Spring Boot | `spring-logs-YYYY.MM.dd` |

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| ES exits immediately | Insufficient memory | Lower `ES_JAVA_OPTS` to `-Xms256m -Xmx256m` |
| `vm.max_map_count` error | Linux kernel setting too low | Run `sudo sysctl -w vm.max_map_count=262144` |
| Kibana stuck on loading screen | ES not ready yet | Wait 2–3 min and refresh |
| Logstash not healthy | Pipeline config syntax error | Run `docker compose logs logstash` to inspect |
| No logs appearing in Kibana | Wrong index pattern | Check index names with `curl http://localhost:9200/_cat/indices?v` |
| Kibana encryption key error | Key shorter than 32 characters | Ensure all `XPACK_*_ENCRYPTIONKEY` values are exactly 32+ characters |

---

## Production Server Checklist

Search for all `# SERVER:` comments in `docker-compose.yml` and `logstash.conf` and apply each one before deploying. Key steps include:

- [ ] Set `xpack.security.enabled=true` on Elasticsearch
- [ ] Generate a Kibana service account token (replaces username/password):
  ```bash
  docker exec -it elasticsearch \
    bin/elasticsearch-service-tokens create elastic/kibana kibana-token
  ```
- [ ] Replace `ELASTICSEARCH_USERNAME` / `ELASTICSEARCH_PASSWORD` in Kibana with `ELASTICSEARCH_SERVICEACCOUNTTOKEN`
- [ ] Generate proper 32-byte encryption keys for Kibana:
  ```bash
  openssl rand -hex 32  # run 3 times, one per key
  ```
- [ ] Increase JVM heap to half of available server RAM (`ES_JAVA_OPTS=-Xms4g -Xmx4g` for 8 GB RAM)
- [ ] Bind Logstash ports to `127.0.0.1` — never expose `0.0.0.0` publicly
- [ ] Place Kibana behind a reverse proxy (Nginx/Traefik) with HTTPS/TLS termination
- [ ] Set `SERVER_PUBLICBASEURL` to your actual domain
- [ ] Bind Elasticsearch to loopback only (`127.0.0.1:9200:9200`)
- [ ] Configure Elasticsearch snapshot/backup for `es_data` volume
- [ ] Update `<destination>` in `logback-spring.xml` from `localhost` to your server IP/hostname
