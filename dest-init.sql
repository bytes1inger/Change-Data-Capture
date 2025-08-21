-- Unified schema with composite PKs and FKs that include source
CREATE TABLE users (
  id INT NOT NULL,
  source VARCHAR(20) NOT NULL,
  name TEXT,
  email TEXT,
  created_at TIMESTAMP,
  PRIMARY KEY (id, source)
);

CREATE TABLE orders (
  id INT NOT NULL,
  source VARCHAR(20) NOT NULL,
  user_id INT NOT NULL,
  user_source VARCHAR(20) NOT NULL,
  amount NUMERIC(12,2),
  created_at TIMESTAMP,
  PRIMARY KEY (id, source),
  FOREIGN KEY (user_id, user_source) REFERENCES users(id, source)
);

-- Helper trigger: if an order arrives without user_source, default it to its own source
CREATE OR REPLACE FUNCTION set_order_user_source() RETURNS trigger AS $$
BEGIN
  IF NEW.user_source IS NULL THEN
    NEW.user_source := NEW.source;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_user_source
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION set_order_user_source();
