-- PreOrderSystem (AuraBake) Seed Data
-- Run this in your Supabase SQL Editor to populate dummy data!

-- Insert some outlets
INSERT INTO public.outlets (id, name, tagline, icon, is_open, queue_count, wait_time) VALUES
('o1', 'Nescafe Center', 'Hot coffee & quick bites', '58145', true, 12, '5-10m'),
('o2', 'Campus Canteen', 'Full meals & thalis', '58330', true, 45, '15-20m'),
('o3', 'Juice Bar', 'Fresh juices & shakes', '58348', false, 0, 'Closed')
ON CONFLICT (id) DO NOTHING;

-- Insert some menu items
INSERT INTO public.menu_items (id, outlet_id, name, description, price, category, icon, is_available) VALUES
('m1', 'o1', 'Cold Coffee', 'Thick creamy cold coffee', 60, 'Beverages', '57917', true),
('m2', 'o1', 'Maggi', 'Classic masala maggi', 40, 'Snacks', '58145', true),
('m3', 'o1', 'Veg Burger', 'Aloo tikki burger with cheese', 55, 'Snacks', '58145', true),
('m4', 'o2', 'Veg Thali', 'Dal, roti, sabzi, rice', 90, 'Meals', '58330', true),
('m5', 'o2', 'Chole Bhature', 'Spicy chole with 2 bhature', 80, 'Meals', '58330', true),
('m6', 'o3', 'Mango Shake', 'Fresh mango shake', 50, 'Beverages', '58348', true)
ON CONFLICT (id) DO NOTHING;

-- To insert dummy orders, we need a user_id which is generated dynamically via Supabase Auth.
-- So we leave orders empty until a user logs in and places one!
