#!/bin/bash

# MSSQL to MSSQL CDC Setup Script

# Function to check if a service is ready
wait_for_service() {
  local host=$1
  local port=$2
  local service=$3
  
  echo "Waiting for $service to be ready..."
  while ! nc -z $host $port; do
    echo "Waiting for $service..."
    sleep 2
  done
  echo "$service is ready!"
}

# Function to replace placeholders in connector config files
configure_connectors() {
  echo "Configuring connectors..."
  
  # MSSQL source connector configuration
  sed -i "s/YOUR_SOURCE_MSSQL_HOST/$SOURCE_MSSQL_HOST/g" mssql-source-connector.json
  sed -i "s/YOUR_SOURCE_MSSQL_USER/$SOURCE_MSSQL_USER/g" mssql-source-connector.json
  sed -i "s/YOUR_SOURCE_MSSQL_PASSWORD/$SOURCE_MSSQL_PASSWORD/g" mssql-source-connector.json
  sed -i "s/YOUR_SOURCE_DATABASE_NAME/$SOURCE_DATABASE/g" mssql-source-connector.json
  sed -i "s/YOUR_TABLE_NAME/$SOURCE_TABLE/g" mssql-source-connector.json
  
  # MSSQL sink connector configuration
  sed -i "s/YOUR_DEST_MSSQL_HOST/$DEST_MSSQL_HOST/g" mssql-sink-connector.json
  sed -i "s/YOUR_DEST_MSSQL_USER/$DEST_MSSQL_USER/g" mssql-sink-connector.json
  sed -i "s/YOUR_DEST_MSSQL_PASSWORD/$DEST_MSSQL_PASSWORD/g" mssql-sink-connector.json
  sed -i "s/YOUR_DEST_DATABASE_NAME/$DEST_DATABASE/g" mssql-sink-connector.json
  sed -i "s/YOUR_DEST_TABLE_NAME/$DEST_TABLE/g" mssql-sink-connector.json
  sed -i "s/YOUR_SOURCE_DATABASE_NAME/$SOURCE_DATABASE/g" mssql-sink-connector.json
  sed -i "s/YOUR_TABLE_NAME/$SOURCE_TABLE/g" mssql-sink-connector.json
}

# Function to register connectors
register_connectors() {
  echo "Registering MSSQL source connector..."
  curl -X POST -H "Content-Type: application/json" --data @mssql-source-connector.json http://localhost:8083/connectors
  
  echo -e "\nWaiting for source connector to initialize..."
  sleep 10
  
  echo -e "\nRegistering MSSQL sink connector..."
  curl -X POST -H "Content-Type: application/json" --data @mssql-sink-connector.json http://localhost:8083/connectors
}

# Function to check connector status
check_status() {
  echo -e "\nChecking connector status..."
  echo -e "\nMSSQL source connector status:"
  curl -s http://localhost:8083/connectors/mssql-source-connector/status
  
  echo -e "\n\nMSSQL sink connector status:"
  curl -s http://localhost:8083/connectors/mssql-sink-connector/status
}

# Main script execution
echo "MSSQL to MSSQL CDC Setup"
echo "========================"

# Get configuration parameters
read -p "Source MSSQL Host: " SOURCE_MSSQL_HOST
read -p "Source MSSQL Port (default: 1433): " SOURCE_MSSQL_PORT
SOURCE_MSSQL_PORT=${SOURCE_MSSQL_PORT:-1433}
read -p "Source MSSQL User: " SOURCE_MSSQL_USER
read -s -p "Source MSSQL Password: " SOURCE_MSSQL_PASSWORD
echo
read -p "Source MSSQL Database: " SOURCE_DATABASE
read -p "Source MSSQL Table: " SOURCE_TABLE

read -p "Destination MSSQL Host: " DEST_MSSQL_HOST
read -p "Destination MSSQL Port (default: 1433): " DEST_MSSQL_PORT
DEST_MSSQL_PORT=${DEST_MSSQL_PORT:-1433}
read -p "Destination MSSQL User: " DEST_MSSQL_USER
read -s -p "Destination MSSQL Password: " DEST_MSSQL_PASSWORD
echo
read -p "Destination MSSQL Database: " DEST_DATABASE
read -p "Destination MSSQL Table: " DEST_TABLE

# Start Docker Compose
echo -e "\nStarting Docker services..."
docker-compose up -d

# Wait for Kafka Connect to be ready
wait_for_service localhost 8083 "Kafka Connect"

# Configure and register connectors
configure_connectors
register_connectors

# Check status
check_status

echo -e "\nSetup complete!"
echo "Monitor the logs with: docker logs cdc-connect -f"