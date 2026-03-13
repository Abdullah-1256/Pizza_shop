-- Create the update_settings RPC function
CREATE OR REPLACE FUNCTION update_settings(
    p_delivery_charges INTEGER,
    p_min_order_amount INTEGER,
    p_contact_number TEXT,
    p_restaurant_status BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update or insert settings
    INSERT INTO settings (delivery_charges, min_order_amount, contact_number, restaurant_status, updated_at)
    VALUES (p_delivery_charges, p_min_order_amount, p_contact_number, p_restaurant_status, NOW())
    ON CONFLICT (id)
    DO UPDATE SET
        delivery_charges = EXCLUDED.delivery_charges,
        min_order_amount = EXCLUDED.min_order_amount,
        contact_number = EXCLUDED.contact_number,
        restaurant_status = EXCLUDED.restaurant_status,
        updated_at = NOW()
    WHERE settings.id = EXCLUDED.id;

END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_settings(INTEGER, INTEGER, TEXT, BOOLEAN) TO authenticated;