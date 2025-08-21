#!/bin/bash

# Script to monitor the MSSQL to MSSQL CDC pipeline

# Function to check connector status
check_connector_status() {
  local connector=$1
  echo -e "\nChecking status of $connector connector..."
  curl -s http://localhost:8083/connectors/$connector/status
}

# Function to list Kafka topics
list_kafka_topics() {
  echo -e "\nListing Kafka topics..."
  docker exec cdc-kafka /usr/bin/kafka-topics --list --bootstrap-server kafka:29092
}

# Function to consume messages from a topic
consume_topic_messages() {
  local topic=$1
  local count=${2:-5}
  echo -e "\nConsuming $count messages from topic $topic..."
  docker exec cdc-kafka /usr/bin/kafka-console-consumer --bootstrap-server kafka:29092 --topic $topic --from-beginning --max-messages $count
}

# Function to check connector tasks
check_connector_tasks() {
  local connector=$1
  echo -e "\nChecking tasks for $connector connector..."
  curl -s http://localhost:8083/connectors/$connector/tasks
}

# Function to check connector config
check_connector_config() {
  local connector=$1
  echo -e "\nChecking configuration for $connector connector..."
  curl -s http://localhost:8083/connectors/$connector/config
}

# Main menu
while true; do
  echo -e "\n===== MSSQL to MSSQL CDC Pipeline Monitor ====="
  echo "1. Check source connector status"
  echo "2. Check sink connector status"
  echo "3. List Kafka topics"
  echo "4. Consume messages from source topic"
  echo "5. Check connector tasks"
  echo "6. Check connector configurations"
  echo "7. View Kafka Connect logs"
  echo "8. Exit"
  
  read -p "Select an option: " option
  
  case $option in
    1)
      check_connector_status "mssql-source-connector"
      ;;
    2)
      check_connector_status "mssql-sink-connector"
      ;;
    3)
      list_kafka_topics
      ;;
    4)
      read -p "Enter topic name: " topic
      read -p "Enter number of messages to consume (default: 5): " count
      count=${count:-5}
      consume_topic_messages "$topic" "$count"
      ;;
    5)
      echo "1. Source connector tasks"
      echo "2. Sink connector tasks"
      read -p "Select connector: " connector_option
      if [ "$connector_option" == "1" ]; then
        check_connector_tasks "mssql-source-connector"
      elif [ "$connector_option" == "2" ]; then
        check_connector_tasks "mssql-sink-connector"
      else
        echo "Invalid option"
      fi
      ;;
    6)
      echo "1. Source connector config"
      echo "2. Sink connector config"
      read -p "Select connector: " connector_option
      if [ "$connector_option" == "1" ]; then
        check_connector_config "mssql-source-connector"
      elif [ "$connector_option" == "2" ]; then
        check_connector_config "mssql-sink-connector"
      else
        echo "Invalid option"
      fi
      ;;
    7)
      echo "Press Ctrl+C to exit logs"
      sleep 2
      docker logs -f cdc-connect
      ;;
    8)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
  
  read -p "Press Enter to continue..."
done
