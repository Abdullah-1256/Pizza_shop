-- Create settings table
CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY DEFAULT 1,
    delivery_charges INTEGER NOT NULL DEFAULT 150,
    min_order_amount INTEGER NOT NULL DEFAULT 500,
    contact_number TEXT NOT NULL DEFAULT '+92 300 1234567',
    restaurant_status BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT single_row_settings CHECK (id = 1)
);

-- Insert default settings if not exists
INSERT INTO settings (id, delivery_charges, min_order_amount, contact_number, restaurant_status)
VALUES (1, 150, 500, '+92 300 1234567', true)
ON CONFLICT (id) DO NOTHING;

-- Enable Row Level Security
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users to read settings
CREATE POLICY "Allow authenticated users to read settings" ON settings
    FOR SELECT USING (auth.role() = 'authenticated');

-- Create policy for authenticated users to update settings
CREATE POLICY "Allow authenticated users to update settings" ON settings
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Create policy for authenticated users to insert settings
CREATE POLICY "Allow authenticated users to insert settings" ON settings
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');