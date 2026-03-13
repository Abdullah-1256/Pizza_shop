-- Delivery Personnel and Location Tracking Setup

-- Create delivery_personnel table
CREATE TABLE IF NOT EXISTS delivery_personnel (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  vehicle_type TEXT DEFAULT 'bike', -- bike, car, scooter
  license_number TEXT,
  is_active BOOLEAN DEFAULT true,
  current_location JSONB, -- {lat: number, lng: number, timestamp: string}
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create delivery_assignments table
CREATE TABLE IF NOT EXISTS delivery_assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  delivery_person_id UUID REFERENCES delivery_personnel(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status TEXT DEFAULT 'assigned', -- assigned, picked_up, en_route, delivered
  estimated_delivery_time TIMESTAMP WITH TIME ZONE,
  actual_delivery_time TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create delivery_locations table for tracking history
CREATE TABLE IF NOT EXISTS delivery_locations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  delivery_person_id UUID REFERENCES delivery_personnel(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  location JSONB NOT NULL, -- {lat: number, lng: number}
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  speed DOUBLE PRECISION,
  heading DOUBLE PRECISION
);

-- Enable RLS
ALTER TABLE delivery_personnel ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_locations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Delivery personnel are viewable by authenticated users"
ON delivery_personnel FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Delivery assignments are viewable by order owners and delivery personnel"
ON delivery_assignments FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM orders WHERE id = order_id
  ) OR
  auth.uid() IN (
    SELECT user_id FROM delivery_personnel WHERE id = delivery_person_id
  )
);

CREATE POLICY "Delivery locations are viewable by order owners and delivery personnel"
ON delivery_locations FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM orders WHERE id = order_id
  ) OR
  auth.uid() IN (
    SELECT user_id FROM delivery_personnel WHERE id = delivery_person_id
  )
);

-- Function to update delivery person location
CREATE OR REPLACE FUNCTION update_delivery_location(
  p_delivery_person_id UUID,
  p_order_id UUID,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_speed DOUBLE PRECISION DEFAULT NULL,
  p_heading DOUBLE PRECISION DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  -- Update current location in delivery_personnel
  UPDATE delivery_personnel
  SET
    current_location = jsonb_build_object(
      'lat', p_lat,
      'lng', p_lng,
      'timestamp', NOW()::text
    ),
    updated_at = NOW()
  WHERE id = p_delivery_person_id;

  -- Insert location history
  INSERT INTO delivery_locations (
    delivery_person_id,
    order_id,
    location,
    speed,
    heading
  ) VALUES (
    p_delivery_person_id,
    p_order_id,
    jsonb_build_object('lat', p_lat, 'lng', p_lng),
    p_speed,
    p_heading
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to assign delivery person to order
CREATE OR REPLACE FUNCTION assign_delivery_person(p_order_id UUID)
RETURNS UUID AS $$
DECLARE
  delivery_person_id UUID;
BEGIN
  -- Find nearest available delivery person (simplified - just pick first available)
  SELECT id INTO delivery_person_id
  FROM delivery_personnel
  WHERE is_active = true
  AND id NOT IN (
    SELECT delivery_person_id FROM delivery_assignments
    WHERE status IN ('assigned', 'picked_up', 'en_route')
  )
  LIMIT 1;

  IF delivery_person_id IS NOT NULL THEN
    -- Create assignment
    INSERT INTO delivery_assignments (
      order_id,
      delivery_person_id,
      estimated_delivery_time
    ) VALUES (
      p_order_id,
      delivery_person_id,
      NOW() + INTERVAL '45 minutes'
    );

    -- Update order status
    UPDATE orders
    SET status = 'assigned', updated_at = NOW()
    WHERE id = p_order_id;
  END IF;

  RETURN delivery_person_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert sample delivery personnel
INSERT INTO delivery_personnel (name, phone, email, vehicle_type, license_number, current_location)
VALUES
  ('Ahmed Khan', '+923001234567', 'ahmed@delivery.com', 'bike', 'DL-12345', '{"lat": 24.8607, "lng": 67.0011, "timestamp": "' || NOW()::text || '"}'),
  ('Sara Ahmed', '+923001234568', 'sara@delivery.com', 'scooter', 'DL-12346', '{"lat": 24.8610, "lng": 67.0015, "timestamp": "' || NOW()::text || '"}'),
  ('Bilal Hussain', '+923001234569', 'bilal@delivery.com', 'bike', 'DL-12347', '{"lat": 24.8595, "lng": 67.0008, "timestamp": "' || NOW()::text || '"}')
ON CONFLICT DO NOTHING;