-- Insert sample products into the products table
-- Run this script to populate the products table with sample data

INSERT INTO products (name, description, price, category, image_url, is_available, created_at) VALUES
-- Pizzas
('Margherita Pizza', 'Classic pizza with tomato sauce, mozzarella cheese, and fresh basil', 899.00, 'Pizza', 'assets/images/pizza_icon.png', true, NOW()),
('Pepperoni Pizza', 'Delicious pizza topped with pepperoni slices and mozzarella cheese', 1099.00, 'Pizza', 'assets/images/pizza_icon.png', true, NOW()),
('BBQ Chicken Pizza', 'Grilled chicken with BBQ sauce, onions, and cilantro', 1299.00, 'Pizza', 'assets/images/pizza_icon.png', true, NOW()),
('Veggie Supreme Pizza', 'Loaded with bell peppers, onions, mushrooms, olives, and tomatoes', 1199.00, 'Pizza', 'assets/images/pizza_icon.png', true, NOW()),
('Hawaiian Pizza', 'Ham and pineapple with mozzarella cheese', 1149.00, 'Pizza', 'assets/images/pizza_icon.png', true, NOW()),

-- Burgers
('Classic Cheese Burger', 'Juicy beef patty with cheese, lettuce, tomato, and special sauce', 649.00, 'Burger', 'assets/images/pizza_icon.png', true, NOW()),
('Chicken Burger', 'Grilled chicken breast with lettuce, tomato, and mayo', 599.00, 'Burger', 'assets/images/pizza_icon.png', true, NOW()),
('BBQ Bacon Burger', 'Beef patty with bacon, BBQ sauce, and cheddar cheese', 799.00, 'Burger', 'assets/images/pizza_icon.png', true, NOW()),

-- Shawarma
('Chicken Shawarma', 'Marinated chicken wrapped in pita bread with garlic sauce', 349.00, 'Shawarma', 'assets/images/pizza_icon.png', true, NOW()),
('Beef Shawarma', 'Tender beef strips with tahini sauce and vegetables', 399.00, 'Shawarma', 'assets/images/pizza_icon.png', true, NOW()),

-- Pasta
('Creamy Alfredo Pasta', 'Fettuccine pasta in creamy Alfredo sauce with grilled chicken', 849.00, 'Pasta', 'assets/images/pizza_icon.png', true, NOW()),
('Spaghetti Bolognese', 'Traditional spaghetti with meat sauce', 799.00, 'Pasta', 'assets/images/pizza_icon.png', true, NOW()),
('Pesto Pasta', 'Pasta tossed in basil pesto sauce with cherry tomatoes', 749.00, 'Pasta', 'assets/images/pizza_icon.png', true, NOW()),

-- Drinks
('Coca Cola', 'Classic Coca Cola soft drink', 99.00, 'Drinks', 'assets/images/pizza_icon.png', true, NOW()),
('Pepsi', 'Refreshing Pepsi cola drink', 99.00, 'Drinks', 'assets/images/pizza_icon.png', true, NOW()),
('Orange Juice', 'Freshly squeezed orange juice', 149.00, 'Drinks', 'assets/images/pizza_icon.png', true, NOW()),
('Mineral Water', 'Pure mineral water', 79.00, 'Drinks', 'assets/images/pizza_icon.png', true, NOW()),
('Iced Tea', 'Refreshing iced tea with lemon', 129.00, 'Drinks', 'assets/images/pizza_icon.png', true, NOW())

ON CONFLICT (id) DO NOTHING;

-- Update the image column to use image_url if image is null
UPDATE products SET image = image_url WHERE image IS NULL AND image_url IS NOT NULL;