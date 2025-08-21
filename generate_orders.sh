#!/bin/bash

# Script to generate users and orders in all source databases
# - New user every minute in each database
# - New order every 15 seconds in each database

# Truncate tables to start fresh
echo "Truncating tables in all source databases..."
for db in src1 src2 src3; do
  echo "Truncating tables in ${db}..."
  echo "6590" | sudo -S docker exec -i cdc-postgres-${db}-1 psql -U postgres -d appdb -c "TRUNCATE TABLE orders RESTART IDENTITY CASCADE;"
  echo "6590" | sudo -S docker exec -i cdc-postgres-${db}-1 psql -U postgres -d appdb -c "TRUNCATE TABLE users RESTART IDENTITY CASCADE;"
done

# Insert initial users
echo "Inserting initial users in all source databases..."
for db in src1 src2 src3; do
  echo "Inserting initial users in ${db}..."
  echo "6590" | sudo -S docker exec -i cdc-postgres-${db}-1 psql -U postgres -d appdb -c "INSERT INTO users (name, email) VALUES ('Alice', 'alice@${db}.com'), ('Bob', 'bob@${db}.com');"
done

# Counters for IDs
declare -A order_counter
declare -A user_counter
for db in src1 src2 src3; do
  order_counter[$db]=1
  user_counter[$db]=3  # Start from 3 since we already have users 1 and 2
done

echo "Starting to generate data in all source databases..."
echo "Press Ctrl+C to stop"

user_timer=0

while true; do
  # Current timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  for db in src1 src2 src3; do
    # Every minute, insert a new user
    if [ $user_timer -eq 0 ]; then
      # Generate a random name
      names=("John" "Jane" "Mike" "Sara" "David" "Emma" "Tom" "Lisa" "Alex" "Olivia")
      name_index=$(( RANDOM % ${#names[@]} ))
      name=${names[$name_index]}
      
      # Generate a random email
      email="${name,,}${user_counter[$db]}@${db}.com"
      
      echo "[$db] Inserting user #${user_counter[$db]}: ${name}, Email: ${email}"
      
      # SQL to insert the user
      user_sql="INSERT INTO users (id, name, email, created_at) VALUES (${user_counter[$db]}, '${name}', '${email}', '${timestamp}');"
      echo "6590" | sudo -S docker exec -i cdc-postgres-${db}-1 psql -U postgres -d appdb -c "${user_sql}"
      
      # Increment the user counter
      user_counter[$db]=$((user_counter[$db] + 1))
    fi
    
    # Generate a random amount between 10 and 1000
    amount=$(( RANDOM % 990 + 10 ))
    
    # Generate a random user ID between 1 and the current max user ID
    max_user_id=$((user_counter[$db] - 1))
    user_id=$(( RANDOM % max_user_id + 1 ))
    
    echo "[$db] Inserting order #${order_counter[$db]}: User ID: ${user_id}, Amount: \$${amount}"
    
    # SQL to insert the order
    order_sql="INSERT INTO orders (id, user_id, amount, created_at) VALUES (${order_counter[$db]}, ${user_id}, ${amount}, '${timestamp}');"
    echo "6590" | sudo -S docker exec -i cdc-postgres-${db}-1 psql -U postgres -d appdb -c "${order_sql}"
    
    # Increment the order counter
    order_counter[$db]=$((order_counter[$db] + 1))
  done
  
  # Increment the user timer (0-3, resets to 0 every 4th iteration = once per minute)
  user_timer=$(( (user_timer + 1) % 4 ))
  
  # Wait for 15 seconds
  sleep 15
done