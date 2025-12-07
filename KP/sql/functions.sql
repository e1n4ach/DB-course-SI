-- ============= ФУНКЦИИ =============

-- 1. Функция расчёта стоимости брони с доп. услугами
CREATE OR REPLACE FUNCTION calculate_booking_total(p_booking_id INT)
RETURNS DECIMAL AS $$
DECLARE
    v_total DECIMAL := 0;
    v_base_price DECIMAL;
    v_services_total DECIMAL := 0;
BEGIN
    -- Получаем базовую цену из тарифа
    SELECT tp.base_price INTO v_base_price
    FROM bookings b
    JOIN tariff_packages tp ON b.tariff_package_id = tp.id
    WHERE b.id = p_booking_id;
    
    v_total := COALESCE(v_base_price, 0);
    
    -- Добавляем стоимость дополнительных услуг
    SELECT COALESCE(SUM(service_price), 0) INTO v_services_total
    FROM booking_services
    WHERE booking_id = p_booking_id;
    
    v_total := v_total + v_services_total;
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- 2. Функция: выручка по фотографам за период
CREATE OR REPLACE FUNCTION get_photographer_income(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    photographer_id INT,
    photographer_name VARCHAR,
    total_bookings INT,
    total_income DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        CONCAT(s.first_name, ' ', s.last_name),
        COUNT(b.id)::INT,
        COALESCE(SUM(b.total_price), 0)::DECIMAL
    FROM staff s
    LEFT JOIN bookings b ON s.id = b.photographer_id 
        AND b.session_date BETWEEN p_start_date AND p_end_date
        AND b.status = 'completed'
    WHERE s.role = 'photographer'
    GROUP BY s.id, s.first_name, s.last_name
    ORDER BY total_income DESC;
END;
$$ LANGUAGE plpgsql;

-- 3. Функция: загруженность залов по дням
CREATE OR REPLACE FUNCTION get_room_usage(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    room_id INT,
    room_name VARCHAR,
    usage_date DATE,
    bookings_count INT,
    total_hours INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sr.id,
        sr.name,
        b.session_date,
        COUNT(b.id)::INT,
        SUM(EXTRACT(EPOCH FROM (b.session_end_time - b.session_start_time))/3600)::INT
    FROM studio_rooms sr
    LEFT JOIN bookings b ON sr.id = b.room_id 
        AND b.session_date BETWEEN p_start_date AND p_end_date
        AND b.status IN ('confirmed', 'completed')
    GROUP BY sr.id, sr.name, b.session_date
    ORDER BY b.session_date DESC, sr.name;
END;
$$ LANGUAGE plpgsql;

-- 4. Функция: статистика проблемных клиентов
CREATE OR REPLACE FUNCTION get_problem_clients_stats()
RETURNS TABLE (
    client_id INT,
    client_name VARCHAR,
    total_bookings INT,
    cancelled_bookings INT,
    total_spent DECIMAL,
    cancellation_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        CONCAT(c.first_name, ' ', c.last_name),
        COUNT(b.id)::INT,
        SUM(CASE WHEN b.status = 'cancelled' THEN 1 ELSE 0 END)::INT,
        COALESCE(SUM(b.total_price), 0)::DECIMAL,
        ROUND(100.0 * SUM(CASE WHEN b.status = 'cancelled' THEN 1 ELSE 0 END) / NULLIF(COUNT(b.id), 0), 2)::DECIMAL
    FROM clients c
    LEFT JOIN bookings b ON c.id = b.client_id
    WHERE c.is_problem_client = TRUE
    GROUP BY c.id, c.first_name, c.last_name
    ORDER BY cancelled_bookings DESC;
END;
$$ LANGUAGE plpgsql;

-- ============= ПРЕДСТАВЛЕНИЯ (VIEWS) =============

-- 1. Представление: ближайшие брони с полной информацией
CREATE OR REPLACE VIEW upcoming_bookings AS
SELECT 
    b.id,
    b.session_date,
    b.session_start_time,
    b.session_end_time,
    CONCAT(c.first_name, ' ', c.last_name) AS client_name,
    c.phone AS client_phone,
    sr.name AS room_name,
    CONCAT(s.first_name, ' ', s.last_name) AS photographer_name,
    tp.name AS package_name,
    b.total_price,
    b.status
FROM bookings b
JOIN clients c ON b.client_id = c.id
JOIN studio_rooms sr ON b.room_id = sr.id
JOIN staff s ON b.photographer_id = s.id
JOIN tariff_packages tp ON b.tariff_package_id = tp.id
WHERE b.session_date >= CURRENT_DATE
    AND b.status IN ('new', 'confirmed')
ORDER BY b.session_date, b.session_start_time;

-- 2. Представление: выручка по залам
CREATE OR REPLACE VIEW room_revenue AS
SELECT 
    sr.id,
    sr.name,
    COUNT(b.id) AS total_sessions,
    SUM(b.total_price) AS total_revenue,
    AVG(b.total_price) AS avg_session_price,
    sr.hourly_rate
FROM studio_rooms sr
LEFT JOIN bookings b ON sr.id = b.room_id 
    AND b.status = 'completed'
GROUP BY sr.id, sr.name, sr.hourly_rate
ORDER BY total_revenue DESC;

-- 3. Представление: топ популярные пакеты
CREATE OR REPLACE VIEW popular_packages AS
SELECT 
    tp.id,
    tp.name,
    tp.session_type,
    tp.base_price,
    COUNT(b.id) AS bookings_count,
    SUM(b.total_price) AS total_revenue
FROM tariff_packages tp
LEFT JOIN bookings b ON tp.id = b.tariff_package_id
    AND b.status IN ('completed', 'confirmed')
GROUP BY tp.id, tp.name, tp.session_type, tp.base_price
ORDER BY bookings_count DESC;

-- ============= ТРИГГЕРЫ =============

-- 1. Триггер: аудит при INSERT в bookings
CREATE OR REPLACE FUNCTION audit_bookings_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, new_values, change_timestamp)
    VALUES ('bookings', 'INSERT', NEW.id, row_to_json(NEW), CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bookings_audit_insert ON bookings;
CREATE TRIGGER bookings_audit_insert
AFTER INSERT ON bookings
FOR EACH ROW
EXECUTE FUNCTION audit_bookings_insert();

-- 2. Триггер: аудит при UPDATE в bookings
CREATE OR REPLACE FUNCTION audit_bookings_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values, change_timestamp)
    VALUES ('bookings', 'UPDATE', NEW.id, row_to_json(OLD), row_to_json(NEW), CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bookings_audit_update ON bookings;
CREATE TRIGGER bookings_audit_update
AFTER UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION audit_bookings_update();

-- 3. Триггер: аудит при DELETE в bookings
CREATE OR REPLACE FUNCTION audit_bookings_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, old_values, change_timestamp)
    VALUES ('bookings', 'DELETE', OLD.id, row_to_json(OLD), CURRENT_TIMESTAMP);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bookings_audit_delete ON bookings;
CREATE TRIGGER bookings_audit_delete
AFTER DELETE ON bookings
FOR EACH ROW
EXECUTE FUNCTION audit_bookings_delete();

-- 4. Триггер: аудит при UPDATE в clients
CREATE OR REPLACE FUNCTION audit_clients_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values, change_timestamp)
    VALUES ('clients', 'UPDATE', NEW.id, row_to_json(OLD), row_to_json(NEW), CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS clients_audit_update ON clients;
CREATE TRIGGER clients_audit_update
AFTER UPDATE ON clients
FOR EACH ROW
EXECUTE FUNCTION audit_clients_update();

-- 5. Триггер: аудит при INSERT в payments
CREATE OR REPLACE FUNCTION audit_payments_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, new_values, change_timestamp)
    VALUES ('payments', 'INSERT', NEW.id, row_to_json(NEW), CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payments_audit_insert ON payments;
CREATE TRIGGER payments_audit_insert
AFTER INSERT ON payments
FOR EACH ROW
EXECUTE FUNCTION audit_payments_insert();
