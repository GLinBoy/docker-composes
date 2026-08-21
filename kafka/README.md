# Kafka

[Apache Kafka](https://kafka.apache.org/) is an open-source distributed event streaming platform for
high-performance data pipelines, streaming analytics, and data integration. This stack runs the
official [apache/kafka image](https://hub.docker.com/r/apache/kafka) (Kafka **4.3.1**) in
**KRaft mode** — the built-in combined broker/controller, no ZooKeeper required — and pairs it with
[Kafka UI](https://github.com/provectus/kafka-ui) (**v0.7.2**), a web dashboard for browsing topics,
producing/consuming, and inspecting consumer groups.

Both containers have working healthchecks: the broker probes the API via
`kafka-broker-api-versions.sh` (the Kafka CLI is at `/opt/kafka/bin`, which is **not** on `PATH`, so
all exec commands use the full path), and Kafka UI is probed with `wget --spider` on its
`/actuator/health` endpoint (the image ships Alpine, which has `wget` but no `curl`).

> Kafka **plaintext** runs with auth/encryption disabled by default — see the Production section
> before exposing it beyond your host.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

For local development the defaults work as-is. When clients connect from other machines, set
`KAFKA_HOST` to your host IP/hostname. Bump `KAFKA_VERSION` / `KAFKA_UI_VERSION` to update the stack.

### 2. Start the Stack

```bash
docker compose up -d
```

### 3. Verify Services

```bash
docker compose ps
```

Both `kafka-broker` and `kafka-ui` should show as "healthy".

### 4. Test Message Production & Consumption

```bash
# Create a test topic
docker compose exec broker /opt/kafka/bin/kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092

# Produce a message
docker compose exec broker bash -c 'echo "Hello, Kafka!" | /opt/kafka/bin/kafka-console-producer.sh --topic test-topic --bootstrap-server localhost:9092'

# Consume the message
docker compose exec broker sh -c '/opt/kafka/bin/kafka-console-consumer.sh --topic test-topic --bootstrap-server localhost:9092 --from-beginning --max-messages 1'
```

### 5. Access Kafka UI

Open [http://localhost:9093](http://localhost:9093) in your browser — you should see the connected
cluster with its topics.

### 6. Stop Kafka

```bash
docker compose down
```

> Containers stop when the host restarts (no restart policy is set, per repository convention).
> To have the stack start automatically, add `restart: unless-stopped` to the services.

## Configuration

### Environment Variables

| Variable           | Required | Description                                                              |
| ------------------ | -------- | ------------------------------------------------------------------------ |
| `KAFKA_VERSION`    | ❌       | Broker image tag (default `apache/kafka:4.3.1`)                          |
| `KAFKA_UI_VERSION` | ❌       | Kafka UI image tag (default `provectuslabs/kafka-ui:v0.7.2`)             |
| `KAFKA_HOST`       | ❌       | Host/IP advertised to external clients (default `localhost`)             |
| `KAFKA_PORT`       | ❌       | Host port for client connections (default `9092`)                        |
| `KAFKA_UI_PORT`    | ❌       | Host port for the web UI, mapped to container 8080 (default `9093`)      |
| `KAFKA_TZ`         | ❌       | Broker timezone (default `UTC`)                                          |
| `KAFKA_UI_TZ`      | ❌       | Kafka UI timezone (default `UTC`)                                        |

> `KAFKA_PORT` and `KAFKA_UI_PORT` only change the host side; the container ports are fixed.
> `KAFKA_HOST` is interpolated into `KAFKA_ADVERTISED_LISTENERS`, so clients know how to reach you.

### Volumes

| Volume       | Purpose        |
| ------------ | -------------- |
| `kafka_data` | Kafka log data |

### Ports

| Port | Service   | Purpose                              |
| ---- | --------- | ------------------------------------ |
| 9092 | broker    | Kafka client connections (PLAINTEXT) |
| 9093 | kafka-ui  | Kafka UI web interface               |

## Updating

1. Bump `KAFKA_VERSION` / `KAFKA_UI_VERSION` in `.env`.
2. Pull and recreate:

```bash
docker compose pull
docker compose up -d
```

## Production Considerations

### 1. Restart Policy

Uncomment `restart: unless-stopped` in `docker-compose.yml` so the stack starts automatically on
boot or failure.

### 2. Security

Kafka ships **plaintext, unauthenticated listeners**. Before exposing it beyond a trusted host:

- Enable SASL authentication (e.g. `SASL_PLAINTEXT`) and SSL/TLS listeners.
- Restrict network access to port `9092` (and to Kafka UI) with your firewall.
- See the [Kafka security docs](https://kafka.apache.org/documentation/#security)
  and [SASL/SCRAM](https://kafka.apache.org/documentation/#security_sasl_scram).

### 3. Persistent Storage

Consider a bind mount for easier backup and management instead of the named volume:

```yaml
volumes:
  kafka_data:
    driver_opts:
      type: none
      o: bind
      device: /data/kafka
```

### 4. Multiple Brokers

This stack is a single-node cluster — enough for development and small workloads. For high
availability, add brokers and controllers, each with a unique `KAFKA_NODE_ID` and a matching
`KAFKA_CONTROLLER_QUORUM_VOTERS` list including every controller. Raise
`KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR` (default `1`, fine for single node) accordingly and see the
[KRaft docs](https://kafka.apache.org/documentation/#kraft) for the controller quorum requirements.

### 5. Resource Limits

Uncomment and tune the `deploy.resources` blocks in `docker-compose.yml`. Kafka is memory- and
disk-hungry — size the broker for your expected throughput.

### 6. Kafka UI Behind a Reverse Proxy

Kafka UI can sit behind one of the reverse-proxy stacks ([Caddy](../caddy/),
[Traefik](../traefik/), [Nginx Proxy Manager](../nginx-proxy-manager/)). Keep the broker off the
public network and reachable only via the Docker network in that case.

## Troubleshooting

### Broker or Kafka UI show as "unhealthy"

```bash
docker compose logs broker
docker compose logs kafka-ui
```

The broker healthcheck queries the API versions endpoint — it needs `start_period` long enough for
KRaft initialization. Kafka UI's healthcheck requests `/actuator/health`.

### Client cannot connect

Ensure `KAFKA_HOST` is reachable from the client and that firewall rules allow it:

```bash
# Advertised listeners currently in effect
docker compose exec broker sh -c 'grep -E "advertised" /etc/kafka/docker/server.properties'
```

### `kafka-*` scripts not found

The Kafka CLI lives in `/opt/kafka/bin`, which is not on `PATH` — always use the full path:

```bash
docker compose exec broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

### Port 9092 or 9093 already in use

Change `KAFKA_PORT` / `KAFKA_UI_PORT` in `.env` and re-run `docker compose up -d`. Remember `KAFKA_HOST`
stays the same — only the port changes.

## Useful Commands

```bash
# View logs
docker compose logs -f broker

# List topics
docker compose exec broker /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# Describe a topic
docker compose exec broker /opt/kafka/bin/kafka-topics.sh --describe --topic test-topic --bootstrap-server localhost:9092

# Show client-facing API versions
docker compose exec broker /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

## Resources

- [Apache Kafka documentation](https://kafka.apache.org/documentation/)
- [apache/kafka image on Docker Hub](https://hub.docker.com/r/apache/kafka)
- [KRaft mode overview](https://developer.confluent.io/learn/kraft/)
- [Kafka UI](https://github.com/provectus/kafka-ui)