# CDC (Change Data Capture) Pipeline

This project demonstrates a Change Data Capture (CDC) pipeline using Debezium, Kafka, and PostgreSQL.

## Architecture

The architecture consists of:

1. **Source Databases**: PostgreSQL databases with CDC enabled using Debezium's PostgreSQL connector
2. **Kafka**: Message broker for streaming changes
3. **Destination Database**: PostgreSQL database where all changes are consolidated

## Directory Structure

- `docker-compose.yaml`: Main configuration file for all services
- `connectors/`: Contains connector configurations
  - `source-*.json`: Source connector configurations for capturing changes from PostgreSQL
  - `debezium-sink*.json`: Sink connector configurations for writing changes to the destination database
- `generate_orders.sh`: Script to generate test data

## Setup Instructions

### 1. Start the Infrastructure

```bash
sudo docker compose up -d
```

This will start:
- Zookeeper
- Kafka
- Three PostgreSQL source databases
- One PostgreSQL destination database
- Two Kafka Connect services (source and sink)

### 2. Register the Source Connectors

First, register the source connectors to capture changes from the source databases:

```bash
# Register source connector for src1
curl -s -X POST -H "Content-Type: application/json" \
  --data @connectors/source-src1.json http://localhost:8083/connectors

# Register source connector for src2
curl -s -X POST -H "Content-Type: application/json" \
  --data @connectors/source-src2.json http://localhost:8083/connectors

# Register source connector for src3
curl -s -X POST -H "Content-Type: application/json" \
  --data @connectors/source-src3.json http://localhost:8083/connectors
```

### 3. Register the Sink Connectors

Important: Register the users sink connector first, as orders have a foreign key dependency on users:

```bash
# Register users sink connector
curl -s -X POST -H "Content-Type: application/json" \
  --data @connectors/debezium-sink-users.json http://localhost:8083/connectors

# Wait a few seconds for users to be synchronized
sleep 10

# Register orders sink connector
curl -s -X POST -H "Content-Type: application/json" \
  --data @connectors/debezium-sink.json http://localhost:8083/connectors
```

### 4. Verify the Setup

Check if the connectors are running:

```bash
# Check source connectors
curl -s http://localhost:8083/connectors

# Check connector status
curl -s http://localhost:8083/connectors/src1-postgres/status
```

### 5. Generate Test Data

Run the script to generate test data:

```bash
./generate_orders.sh
```

This script will:
- Truncate the tables to start fresh
- Insert initial users
- Insert a new user every minute
- Insert a new order every 15 seconds

### 6. Monitor the Data Flow

Check if data is flowing to the destination database:

```bash
# Check users in the destination database
sudo docker exec -it cdc-postgres-dest-1 psql -U postgres -d unifieddb -c "SELECT * FROM users;"

# Check orders in the destination database
sudo docker exec -it cdc-postgres-dest-1 psql -U postgres -d unifieddb -c "SELECT * FROM orders;"
```

## Troubleshooting

### Connector Issues

If connectors fail to start or data is not flowing:

1. Check connector status:
   ```bash
   curl -s http://localhost:8083/connectors/src1-postgres/status
   ```

2. Check connector logs:
   ```bash
   sudo docker logs cdc-connect-source-1
   sudo docker logs cdc-connect-sink-1
   ```

3. Check if data is in Kafka topics:
   ```bash
   sudo docker exec -it cdc-kafka-1 /usr/bin/kafka-topics --list --bootstrap-server localhost:9092
   sudo docker exec -it cdc-kafka-1 /usr/bin/kafka-console-consumer --bootstrap-server localhost:9092 --topic src1.public.orders --from-beginning --max-messages 1
   ```

### Database Issues

If there are issues with the databases:

1. Check if the databases are running:
   ```bash
   sudo docker ps | grep postgres
   ```

2. Check database logs:
   ```bash
   sudo docker logs cdc-postgres-src1-1
   sudo docker logs cdc-postgres-dest-1
   ```

## Notes

- The sink connectors must be registered in the correct order (users before orders) due to foreign key constraints.
- The CDC pipeline uses the Debezium PostgreSQL connector for capturing changes and the JDBC sink connector for writing changes.
- The source connector captures changes in the "after" field of the event, which is extracted by the sink connector.
