-- Customer Auto-Sync with auth.users
-- Automatic insertion of customers when users register
-- Skips users with role "admin"

-- Function to insert customer on user registration
CREATE OR REPLACE FUNCTION handle_new_customer()
RETURNS TRIGGER AS $$
BEGIN
  -- Skip if user has admin role
  IF (SELECT au.raw_user_meta_data->>'role' FROM auth.users au WHERE au.id = NEW.id) = 'admin' THEN
    RETURN NEW;
  END IF;

  -- Insert into customers table
  INSERT INTO customers (id, full_name, email, phone, address, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.name, (SELECT au.raw_user_meta_data->>'name' FROM auth.users au WHERE au.id = NEW.id), (SELECT au.email FROM auth.users au WHERE au.id = NEW.id)),
    (SELECT au.email FROM auth.users au WHERE au.id = NEW.id),
    NEW.phone,
    NEW.address,
    NEW.created_at
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on profiles insert (assuming profiles is inserted on user registration)
CREATE TRIGGER trigger_new_customer
AFTER INSERT ON profiles
FOR EACH ROW EXECUTE FUNCTION handle_new_customer();

-- Manual sync function for existing users
CREATE OR REPLACE FUNCTION manual_sync_customers()
RETURNS void AS $$
BEGIN
  -- Insert customers for existing profiles that don't have customer records
  INSERT INTO customers (id, full_name, email, phone, address, created_at)
  SELECT
    p.id,
    COALESCE(p.name, au.raw_user_meta_data->>'name', au.email),
    au.email,
    p.phone,
    p.address,
    p.created_at
  FROM profiles p
  JOIN auth.users au ON p.id = au.id
  LEFT JOIN customers c ON p.id = c.id
  WHERE c.id IS NULL
    AND COALESCE(au.raw_user_meta_data->>'role', '') != 'admin';

  -- Update existing customers with latest profile data
  UPDATE customers
  SET
    full_name = COALESCE(c.full_name, p.name, au.raw_user_meta_data->>'name', au.email),
    email = au.email,
    phone = COALESCE(c.phone, p.phone),
    address = COALESCE(c.address, p.address)
  FROM profiles p
  JOIN auth.users au ON p.id = au.id
  WHERE customers.id = p.id;
END;
$$ LANGUAGE plpgsql;

-- To run manual sync:
-- SELECT manual_sync_customers();