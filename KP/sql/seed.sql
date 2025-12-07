-- ============= SEED DATA - CLEAN RELOAD =============

-- Drop all data in correct order
DELETE FROM booking_services;
DELETE FROM maintenance_log;
DELETE FROM payments;
DELETE FROM bookings;
DELETE FROM equipment;
DELETE FROM additional_services;
DELETE FROM tariff_packages;
DELETE FROM clients;
DELETE FROM staff;
DELETE FROM studio_rooms;

-- Reset sequences
ALTER SEQUENCE clients_id_seq RESTART WITH 1;
ALTER SEQUENCE staff_id_seq RESTART WITH 1;
ALTER SEQUENCE studio_rooms_id_seq RESTART WITH 1;
ALTER SEQUENCE equipment_id_seq RESTART WITH 1;
ALTER SEQUENCE tariff_packages_id_seq RESTART WITH 1;
ALTER SEQUENCE additional_services_id_seq RESTART WITH 1;
ALTER SEQUENCE bookings_id_seq RESTART WITH 1;
ALTER SEQUENCE payments_id_seq RESTART WITH 1;
ALTER SEQUENCE booking_services_id_seq RESTART WITH 1;
ALTER SEQUENCE maintenance_log_id_seq RESTART WITH 1;

-- ============= CLIENTS (100) =============
INSERT INTO clients (first_name, last_name, email, phone, is_problem_client, notes)
SELECT 'Client' || i, 'Last' || i, 'client_' || i || '@test.com', '+7-999-' || LPAD(i::text, 6, '0'), random() < 0.1, NULL
FROM generate_series(1, 100) AS t(i);

-- ============= STAFF (20) =============
INSERT INTO staff (first_name, last_name, email, phone, role, hourly_rate, is_active)
SELECT 'Staff' || i, 'Last' || i, 'staff_' || i || '@test.com', '+7-999-' || LPAD(i::text, 6, '0'),
    CASE (i % 3) WHEN 0 THEN 'photographer' WHEN 1 THEN 'makeup_artist' ELSE 'admin' END,
    1000 + (i * 100), true
FROM generate_series(1, 20) AS t(i);

-- ============= STUDIO_ROOMS (8) =============
INSERT INTO studio_rooms (name, capacity, base_equipment, status, hourly_rate)
VALUES
    ('Studio A', 10, 'Equipment A', 'available', 2000),
    ('Studio B', 15, 'Equipment B', 'available', 2500),
    ('Studio C', 20, 'Equipment C', 'available', 3000),
    ('Studio D', 8, 'Equipment D', 'available', 1800),
    ('Studio E', 30, 'Equipment E', 'available', 2200),
    ('Studio F', 6, 'Equipment F', 'maintenance', 1600),
    ('Studio G', 15, 'Equipment G', 'available', 3000),
    ('Studio H', 12, 'Equipment H', 'available', 1700);

-- ============= EQUIPMENT (100) =============
INSERT INTO equipment (name, equipment_type, serial_number, status, room_id, purchase_date, last_maintenance, notes)
SELECT 'Equipment ' || i, 
    CASE (i % 7) WHEN 0 THEN 'camera' WHEN 1 THEN 'lens' WHEN 2 THEN 'light' WHEN 3 THEN 'tripod' WHEN 4 THEN 'reflector' WHEN 5 THEN 'backdrop' ELSE 'other' END,
    'SN-' || LPAD(i::text, 5, '0'),
    CASE (i % 3) WHEN 0 THEN 'working' WHEN 1 THEN 'maintenance' ELSE 'broken' END,
    (i % 8) + 1, 
    NOW()::date - 365, 
    NOW()::date, 
    NULL
FROM generate_series(1, 100) AS t(i);

-- ============= TARIFF_PACKAGES (15) =============
INSERT INTO tariff_packages (name, session_type, duration_minutes, base_price, included_photos, included_edits, description, is_active)
SELECT 'Package ' || i,
    CASE (i % 5) WHEN 0 THEN 'family' WHEN 1 THEN 'product' WHEN 2 THEN 'love_story' WHEN 3 THEN 'portrait' ELSE 'event' END,
    60 + (i * 30), 5000 + (i * 1000), 100 + (i * 50), 20 + (i * 5), 'Description ' || i, true
FROM generate_series(1, 15) AS t(i);

-- ============= ADDITIONAL_SERVICES (15) =============
INSERT INTO additional_services (name, service_type, price, description, is_available)
SELECT 'Service ' || i,
    CASE (i % 6) WHEN 0 THEN 'makeup' WHEN 1 THEN 'printing' WHEN 2 THEN 'props' WHEN 3 THEN 'album' WHEN 4 THEN 'retouching' ELSE 'other' END,
    1000 + (i * 500), 'Service description ' || i, true
FROM generate_series(1, 15) AS t(i);

-- ============= BOOKINGS (300) =============
INSERT INTO bookings (client_id, room_id, photographer_id, tariff_package_id, session_date, session_start_time, session_end_time, total_price, status, notes)
SELECT 
    (i % 100) + 1, 
    (i % 8) + 1, 
    (i % 20) + 1, 
    (i % 15) + 1, 
    CURRENT_DATE + (i % 30),
    (LPAD(((i + 8) % 16)::text, 2, '0') || ':00:00')::time,
    (LPAD(((i + 10) % 16)::text, 2, '0') || ':00:00')::time,
    5000 + (i * 100), 
    CASE (i % 4) WHEN 0 THEN 'new' WHEN 1 THEN 'confirmed' WHEN 2 THEN 'completed' ELSE 'cancelled' END, 
    NULL
FROM generate_series(1, 300) AS t(i);

-- ============= PAYMENTS (250) =============
INSERT INTO payments (booking_id, amount, payment_method, payment_date, status, notes)
SELECT 
    (i % 300) + 1, 
    5000 + (i * 50), 
    CASE (i % 3) WHEN 0 THEN 'card' WHEN 1 THEN 'cash' ELSE 'transfer' END,
    NOW() - INTERVAL '30 days', 
    CASE (i % 2) WHEN 0 THEN 'completed' ELSE 'pending' END, 
    NULL
FROM generate_series(1, 250) AS t(i);

-- ============= BOOKING_SERVICES (400) =============
INSERT INTO booking_services (booking_id, service_id, quantity, service_price)
SELECT 
    (i % 300) + 1, 
    (i % 15) + 1, 
    (i % 3) + 1, 
    1000 + (i * 50)
FROM generate_series(1, 400) AS t(i);

-- ============= MAINTENANCE_LOG (200) =============
INSERT INTO maintenance_log (equipment_id, maintenance_type, description, cost, maintenance_date, next_maintenance_date, performed_by)
SELECT 
    (i % 100) + 1,
    CASE (i % 4) WHEN 0 THEN 'repair' WHEN 1 THEN 'cleaning' WHEN 2 THEN 'inspection' ELSE 'calibration' END,
    'Maintenance description ' || i, 
    1000 + (i * 100), 
    NOW()::date - (i % 180), 
    NOW()::date + (i % 180), 
    'Service Center ' || ((i % 5) + 1)::text
FROM generate_series(1, 200) AS t(i);

-- ============= TOTAL STATS =============
SELECT 
    (SELECT COUNT(*) FROM clients) as clients,
    (SELECT COUNT(*) FROM staff) as staff,
    (SELECT COUNT(*) FROM studio_rooms) as rooms,
    (SELECT COUNT(*) FROM equipment) as equipment,
    (SELECT COUNT(*) FROM tariff_packages) as tariffs,
    (SELECT COUNT(*) FROM additional_services) as services,
    (SELECT COUNT(*) FROM bookings) as bookings,
    (SELECT COUNT(*) FROM payments) as payments,
    (SELECT COUNT(*) FROM booking_services) as booking_services,
    (SELECT COUNT(*) FROM maintenance_log) as maintenance;
