SELECT pg_advisory_lock(424242);

CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL CHECK (price > 0)
);

INSERT INTO products (name, price)
  SELECT * FROM (VALUES ('Maize seed 10kg', 15000.00), ('Fertiliser 50kg', 32000.00), ('Knapsack sprayer', 25000.00)) AS seed(name, price)
  WHERE NOT EXISTS (SELECT 1 FROM products);

CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  total_price NUMERIC(12, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending'
  CHECK (status IN ('pending', 'paid', 'delivered', 'cancelled'));
ALTER TABLE orders ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

SELECT pg_advisory_unlock(424242);
