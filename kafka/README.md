# Kafka

[Apache Kafka](https://kafka.apache.org/) is an open-source distributed event streaming platform used for high-performance data pipelines, streaming analytics, and data integration.

This stack runs **Kafka 4.3.0** in **KRaft mode** — no ZooKeeper required. It also includes **Kafka UI** for web-based cluster management.

## Quick Start

### 1. Start Kafka

```bash
docker compose up -d
```

### 2. Verify Services

```bash
docker compose ps
```

All services should show as "healthy".

### 3. Test Message Production & Consumption

```bash
# Create a test topic
docker compose exec broker kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092

# Produce a message
docker compose exec broker bash -c 'echo "Hello, Kafka!" | kafka-console-producer.sh --topic test-topic --bootstrap-server localhost:9092'

# Consume messages
docker compose exec broker kafka-console-consumer.sh --topic test-topic --bootstrap-server localhost:9092 --from-beginning
```

### 4. Access Kafka UI

Open [http://localhost:9093](http://localhost:9093) in your browser.

### 5. Stop Kafka

```bash
docker compose down
```

## Ports

| Port  | Service   | Purpose                          |
|-------|-----------|----------------------------------|
| 9092  | broker    | Kafka client connections         |
| 9093  | kafka-ui  | Kafka UI web interface           |

## Volumes

| Volume       | Purpose          |
|-------------|------------------|
| `kafka_data` | Kafka data logs  |

## Production Considerations

### Before Deploying to Production:

1. **Security**

   Kafka does not enable authentication or encryption by default. For production:
   - Configure SSL/TLS listeners
   - Enable SASL authentication
   - Restrict network access to port 9092

2. **Resource Limits**

   Uncomment the `deploy.resources` block in `docker-compose.yml` and adjust CPU/memory limits based on expected throughput.

3. **Persistent Storage**

   Consider using a bind mount instead of a named volume for easier backup and management:
   ```yaml
   volumes:
     - /data/kafka:/var/lib/kafka/data
   ```

4. **Multiple Brokers**

   For production, run multiple broker instances for high availability. Each broker needs a unique `KAFKA_NODE_ID` and `KAFKA_CONTROLLER_QUORUM_VOTERS` entry.

## Troubleshooting

### Broker won't start

Check the logs:
```bash
docker compose logs broker
```

### Client cannot connect

Ensure the `KAFKA_HOST` environment variable is set to the correct hostname/IP if connecting from outside Docker:
```bash
KAFKA_HOST=your-server-ip
```

## Useful Commands

```bash
# View logs
docker compose logs -f broker

# List topics
docker compose exec broker kafka-topics.sh --list --bootstrap-server localhost:9092

# Describe a topic
docker compose exec broker kafka-topics.sh --describe --topic test-topic --bootstrap-server localhost:9092

# View broker version
docker compose exec broker kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

## Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Kafka UI](https://github.com/provectus/kafka-ui)
- [KRaft Mode Overview](https://developer.confluent.io/learn/kraft/)