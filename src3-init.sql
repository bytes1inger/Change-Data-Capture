CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  amount NUMERIC(12,2),
  created_at TIMESTAMP DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO users (name,email) VALUES
 ('Trent','trent@src3.com'),
 ('Peggy','peggy@src3.com');

INSERT INTO orders (user_id,amount) VALUES
 (1,300), (2,400);
