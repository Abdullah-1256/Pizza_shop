-- Customer View
-- This view provides customer data for admin panel display

CREATE OR REPLACE VIEW customers AS
SELECT
  p.id,
  p.email,
  p.name as full_name,
  p.phone,
  p.address,
  p.created_at,
  COALESCE(order_stats.order_count, 0) as order_count,
  COALESCE(order_stats.total_spent, 0.0) as total_spent
FROM profiles p
LEFT JOIN (
  SELECT
    user_id,
    COUNT(*) as order_count,
    SUM(total_price) as total_spent
  FROM orders
  GROUP BY user_id
) order_stats ON p.id = order_stats.user_id;

-- Customer Statistics View
-- Provides aggregate statistics for admin dashboard

CREATE OR REPLACE VIEW customer_stats AS
SELECT
  COUNT(*) as total_customers,
  COUNT(CASE WHEN order_count > 0 THEN 1 END) as active_customers,
  COALESCE(SUM(order_count), 0) as total_orders,
  COALESCE(SUM(total_spent), 0.0) as total_revenue
FROM customers;