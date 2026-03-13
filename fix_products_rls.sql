-- Fix Row Level Security for products table
-- Allow public read access to products for customer app

-- Disable RLS on products table to allow anonymous access
ALTER TABLE products DISABLE ROW LEVEL SECURITY;

-- Alternative: If you want to keep RLS enabled, create a policy
-- DROP POLICY IF EXISTS "Products are viewable by everyone" ON products;
-- CREATE POLICY "Products are viewable by everyone"
-- ON products FOR SELECT
-- USING (is_available = true);

-- Verify the table structure
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'products';