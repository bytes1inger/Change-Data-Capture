# MSSQL to MSSQL CDC Pipeline

This guide explains how to set up a Change Data Capture (CDC) pipeline from an external Microsoft SQL Server (MSSQL) database to another external MSSQL database using Kafka and Debezium.

## Prerequisites

- External source Microsoft SQL Server database with CDC enabled
- External destination Microsoft SQL Server database
- Docker and Docker Compose installed on the host machine
- Network connectivity from the host to both databases

## MSSQL Source Requirements

For SQL Server to work with Debezium, ensure:

1. SQL Server is Enterprise, Standard, or Developer Edition (Express does not support CDC)
2. CDC is enabled on the database:
   ```sql
   -- Enable CDC on the database
   USE [YourDatabase]
   GO
   EXEC sys.sp_cdc_enable_db
   GO
   
   -- Enable CDC on specific table
   EXEC sys.sp_cdc_enable_table
   @source_schema = 'dbo',
   @source_name = 'YourTable',
   @role_name = NULL,
   @supports_net_changes = 1
   GO
   ```

3. The SQL Server user has appropriate permissions:
   ```sql
   USE [YourDatabase]
   GO
   CREATE LOGIN debezium WITH PASSWORD = 'StrongPassword123!'
   GO
   CREATE USER debezium FOR LOGIN debezium
   GO
   EXEC sp_addrolemember 'db_owner', 'debezium'
   GO
   ```

4. SQL Server Agent is running (required for CDC)

## MSSQL Destination Requirements

For the destination MSSQL:

1. Ensure the database exists and has the appropriate schema
2. The SQL Server user has appropriate permissions to write to tables
3. Enable TCP/IP in SQL Server Configuration Manager

## Setup Instructions

### 1. Configure the Docker Environment

Edit the `docker-compose.yaml` file to adjust any necessary settings.

### 2. Configure the Connectors

1. Edit `mssql-source-connector.json`:
   - Update `database.hostname` with your source MSSQL server address
   - Update `database.user` and `database.password`
   - Update `database.dbname` with your source database name
   - Update `table.include.list` with your table name (format: dbo.TableName)

2. Edit `mssql-sink-connector.json`:
   - Update `connection.url` with your destination MSSQL server address and database name
   - Update `connection.user` and `connection.password`
   - Update `topics` to match the source database and table names
   - Update `table.name.format` with your destination table name
   - Adjust `pk.fields` to match your primary key column(s)

### 3. Start the Services

```bash
docker-compose up -d
```

### 4. Register the Connectors

```bash
# Register MSSQL source connector
curl -X POST -H "Content-Type: application/json" --data @mssql-source-connector.json http://localhost:8083/connectors

# Wait for the source connector to initialize
sleep 10

# Register MSSQL sink connector
curl -X POST -H "Content-Type: application/json" --data @mssql-sink-connector.json http://localhost:8083/connectors
```

### 5. Monitor the Connectors

```bash
# Check connector status
curl -s http://localhost:8083/connectors/mssql-source-connector/status | jq
curl -s http://localhost:8083/connectors/mssql-sink-connector/status | jq

# Check for topics
docker exec cdc-kafka /usr/bin/kafka-topics --list --bootstrap-server kafka:29092
```

## Troubleshooting

### Connection Issues

1. Ensure both databases are accessible from the Docker host
2. Check network connectivity using tools like `telnet` or `nc`:
   ```bash
   telnet YOUR_SOURCE_MSSQL_HOST 1433
   telnet YOUR_DEST_MSSQL_HOST 1433
   ```

### Connector Issues

1. Check connector logs:
   ```bash
   docker logs cdc-connect
   ```

2. Verify connector status:
   ```bash
   curl -s http://localhost:8083/connectors/mssql-source-connector/status
   curl -s http://localhost:8083/connectors/mssql-sink-connector/status
   ```

### CDC Issues

1. Verify CDC is enabled on the database:
   ```sql
   SELECT name, is_cdc_enabled FROM sys.databases WHERE name = 'YourDatabase'
   ```

2. Verify CDC is enabled on the table:
   ```sql
   SELECT name, is_tracked_by_cdc FROM sys.tables WHERE name = 'YourTable'
   ```

3. Check if the SQL Server Agent is running (required for CDC)

## Security Considerations

1. Use secure passwords and don't commit them to version control
2. Consider using environment variables for sensitive information
3. Implement network security to restrict access to your databases
4. Enable SSL/TLS for database connections where possible

## Additional Resources

- [Debezium SQL Server Connector Documentation](https://debezium.io/documentation/reference/connectors/sqlserver.html)
- [SQL Server CDC Documentation](https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/enable-and-disable-change-data-capture-sql-server)