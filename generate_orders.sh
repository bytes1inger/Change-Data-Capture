#!/bin/bash

# Script to generate users and orders in source database 1
# - New user every minute
# - New order every 15 seconds

# Truncate tables to start fresh
echo "Truncating tables..."
echo "6590" | sudo -S docker exec -i cdc-postgres-src1-1 psql -U postgres -d appdb -c "TRUNCATE TABLE orders RESTART IDENTITY CASCADE;"
echo "6590" | sudo -S docker exec -i cdc-postgres-src1-1 psql -U postgres -d appdb -c "TRUNCATE TABLE users RESTART IDENTITY CASCADE;"

# Insert initial users
echo "Inserting initial users..."
echo "6590" | sudo -S docker exec -i cdc-postgres-src1-1 psql -U postgres -d appdb -c "INSERT INTO users (name, email) VALUES ('Alice', 'alice@src1.com'), ('Bob', 'bob@src1.com');"

# Counters for IDs
order_counter=1
user_counter=3  # Start from 3 since we already have users 1 and 2

echo "Starting to generate data in source database 1..."
echo "Press Ctrl+C to stop"

user_timer=0

while true; do
  # Current timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Every minute, insert a new user
  if [ $user_timer -eq 0 ]; then
    # Generate a random name
    names=("John" "Jane" "Mike" "Sara" "David" "Emma" "Tom" "Lisa" "Alex" "Olivia")
    name_index=$(( RANDOM % ${#names[@]} ))
    name=${names[$name_index]}
    
    # Generate a random email
    email="${name,,}${user_counter}@src1.com"
    
    echo "Inserting user #${user_counter}: ${name}, Email: ${email}"
    
    # SQL to insert the user
    user_sql="INSERT INTO users (id, name, email, created_at) VALUES (${user_counter}, '${name}', '${email}', '${timestamp}');"
    echo "6590" | sudo -S docker exec -i cdc-postgres-src1-1 psql -U postgres -d appdb -c "${user_sql}"
    
    # Increment the user counter
    user_counter=$((user_counter + 1))
  fi
  
  # Generate a random amount between 10 and 1000
  amount=$(( RANDOM % 990 + 10 ))
  
  # Generate a random user ID between 1 and the current max user ID
  max_user_id=$((user_counter - 1))
  user_id=$(( RANDOM % max_user_id + 1 ))
  
  echo "Inserting order #${order_counter}: User ID: ${user_id}, Amount: \$${amount}"
  
  # SQL to insert the order
  order_sql="INSERT INTO orders (id, user_id, amount, created_at) VALUES (${order_counter}, ${user_id}, ${amount}, '${timestamp}');"
  echo "6590" | sudo -S docker exec -i cdc-postgres-src1-1 psql -U postgres -d appdb -c "${order_sql}"
  
  # Increment the order counter
  order_counter=$((order_counter + 1))
  
  # Increment the user timer (0-3, resets to 0 every 4th iteration = once per minute)
  user_timer=$(( (user_timer + 1) % 4 ))
  
  # Wait for 15 seconds
  sleep 15
done
