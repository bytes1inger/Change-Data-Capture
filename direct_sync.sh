#!/bin/bash

# Script to directly sync data from source database to destination database
# This bypasses the CDC pipeline and is a temporary solution

# Counter for order IDs
counter=2000

echo "Starting direct sync from source to destination..."
echo "Press Ctrl+C to stop"

while true; do
  # Generate a random amount between 10 and 1000
  amount=$(( RANDOM % 990 + 10 ))
  
  # Generate a random user ID between 1 and 2
  user_id=$(( RANDOM % 2 + 1 ))
  
  # Current timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  echo "Inserting order #${counter}: User ID: ${user_id}, Amount: \$${amount}"
  
  # Insert into source database
  src_sql="INSERT INTO orders (id, user_id, amount, created_at) VALUES (${counter}, ${user_id}, ${amount}, '${timestamp}');"
  echo "6590" | sudo -S docker exec -i cdc-postgres-src1-1 psql -U postgres -d appdb -c "${src_sql}"
  
  # Insert the same data into destination database
  dest_sql="INSERT INTO orders (id, source, user_id, user_source, amount, created_at) VALUES (${counter}, 'SRC1', ${user_id}, 'SRC1', ${amount}, '${timestamp}');"
  echo "6590" | sudo -S docker exec -i cdc-postgres-dest-1 psql -U postgres -d unifieddb -c "${dest_sql}"
  
  # Increment the counter
  counter=$((counter + 1))
  
  # Wait for 10 seconds
  sleep 10
done
