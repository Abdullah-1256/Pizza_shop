-- Enable RLS on users table if not already enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own data (except admins)
CREATE POLICY "Users can view own data" ON users
FOR SELECT USING (
  auth.uid() = id OR
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
  )
);

-- Policy: Users can update their own data (except banned status)
CREATE POLICY "Users can update own data" ON users
FOR UPDATE USING (
  auth.uid() = id AND
  is_banned = false
)
WITH CHECK (
  auth.uid() = id AND
  is_banned = false AND
  -- Prevent users from changing their own ban status or role
  OLD.is_banned = is_banned AND
  OLD.role = role
);

-- Policy: Only admins can update ban status and roles
CREATE POLICY "Admins can update all user data" ON users
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
  )
);

-- Policy: Only non-banned users can insert new data
CREATE POLICY "Non-banned users can insert" ON users
FOR INSERT WITH CHECK (
  is_banned = false
);

-- Policy: Only admins can delete users
CREATE POLICY "Admins can delete users" ON users
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
  )
);

-- Enable RLS on orders table if not already enabled
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Policy: Banned users cannot create orders
CREATE POLICY "Banned users cannot create orders" ON orders
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND is_banned = false
  )
);

-- Policy: Users can view their own orders, admins can view all
CREATE POLICY "Users can view orders" ON orders
FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
  )
);

-- Policy: Users can update their own orders, admins can update all
CREATE POLICY "Users can update orders" ON orders
FOR UPDATE USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
  )
);

-- Enable RLS on order_items table
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own order items, admins can view all
CREATE POLICY "Users can view order items" ON order_items
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND (orders.user_id = auth.uid() OR
         EXISTS (
           SELECT 1 FROM users
           WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
         ))
  )
);

-- Enable RLS on complaints table
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;

-- Policy: Banned users cannot create complaints
CREATE POLICY "Banned users cannot create complaints" ON complaints
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND is_banned = false
  )
);

-- Policy: Users can view their own complaints, admins can view all
CREATE POLICY "Users can view complaints" ON complaints
FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
  )
);

-- Policy: Users can update their own complaints, admins can update all
CREATE POLICY "Users can update complaints" ON complaints
FOR UPDATE USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
  )
);

-- Enable RLS on products table
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view available products
CREATE POLICY "Everyone can view products" ON products
FOR SELECT USING (is_available = true);

-- Policy: Only admins can manage products
CREATE POLICY "Admins can manage products" ON products
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
  )
);

-- Create function to check if user is banned
CREATE OR REPLACE FUNCTION is_user_banned(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = user_id AND is_banned = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin' AND is_banned = false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;