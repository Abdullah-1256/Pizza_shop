-- Add missing columns to products table
-- This script adds the 'image' column and ensures 'is_available' column exists

-- Add image column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'image') THEN
        ALTER TABLE products ADD COLUMN image TEXT;
    END IF;
END $$;

-- Add is_available column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'is_available') THEN
        ALTER TABLE products ADD COLUMN is_available BOOLEAN DEFAULT true;
    END IF;
END $$;

-- Add created_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'created_at') THEN
        ALTER TABLE products ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Add updated_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'updated_at') THEN
        ALTER TABLE products ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Create or replace trigger to update updated_at on row changes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();