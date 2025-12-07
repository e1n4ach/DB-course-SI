-- ============= ПРИМЕРЫ EXPLAIN ANALYZE =============
-- Эти запросы показывают, как индексы улучшают производительность

-- 1. Поиск клиентов по email БЕЗ индекса (если бы его не было)
EXPLAIN ANALYZE
SELECT * FROM clients WHERE email = 'ivan.petrov@email.com';

-- 2. Список броней по дате
EXPLAIN ANALYZE
SELECT b.id, b.session_date, c.first_name, c.last_name, sr.name, s.first_name
FROM bookings b
JOIN clients c ON b.client_id = c.id
JOIN studio_rooms sr ON b.room_id = sr.id
JOIN staff s ON b.photographer_id = s.id
WHERE b.session_date >= '2025-12-15' AND b.status = 'confirmed'
ORDER BY b.session_date;

-- 3. Выручка по фотографам
EXPLAIN ANALYZE
SELECT 
    s.id,
    CONCAT(s.first_name, ' ', s.last_name) AS photographer,
    COUNT(b.id) AS total_bookings,
    SUM(b.total_price) AS total_income
FROM staff s
LEFT JOIN bookings b ON s.id = b.photographer_id AND b.status = 'completed'
WHERE s.role = 'photographer'
GROUP BY s.id, s.first_name, s.last_name
ORDER BY total_income DESC;

-- 4. Поиск броней по клиенту
EXPLAIN ANALYZE
SELECT * FROM bookings 
WHERE client_id = 1 AND status IN ('confirmed', 'completed')
ORDER BY session_date DESC;

-- 5. Загруженность залов за период
EXPLAIN ANALYZE
SELECT 
    sr.id,
    sr.name,
    COUNT(b.id) AS bookings_count,
    SUM(EXTRACT(EPOCH FROM (b.session_end_time - b.session_start_time))/3600) AS total_hours
FROM studio_rooms sr
LEFT JOIN bookings b ON sr.id = b.room_id 
    AND b.session_date BETWEEN '2025-12-01' AND '2025-12-31'
    AND b.status IN ('confirmed', 'completed')
GROUP BY sr.id, sr.name
ORDER BY bookings_count DESC;

-- Версия с агрегированными данными (сложный запрос)
EXPLAIN ANALYZE
SELECT 
    b.session_date,
    sr.name,
    COUNT(*) AS sessions_count,
    SUM(b.total_price) AS daily_revenue,
    AVG(b.total_price) AS avg_price
FROM bookings b
JOIN studio_rooms sr ON b.room_id = sr.id
WHERE b.status = 'completed'
    AND b.session_date BETWEEN '2025-12-01' AND '2025-12-31'
GROUP BY b.session_date, sr.name
HAVING COUNT(*) > 0
ORDER BY b.session_date DESC, daily_revenue DESC;

-- 6. Статистика платежей
EXPLAIN ANALYZE
SELECT 
    p.payment_method,
    p.status,
    COUNT(*) AS count,
    SUM(p.amount) AS total,
    AVG(p.amount) AS average
FROM payments p
WHERE p.payment_date >= '2025-12-01'
GROUP BY p.payment_method, p.status;

-- 7. Журнал аудита последних изменений
EXPLAIN ANALYZE
SELECT * FROM audit_log 
WHERE table_name IN ('bookings', 'clients', 'payments')
    AND change_timestamp >= NOW() - INTERVAL '7 days'
ORDER BY change_timestamp DESC
LIMIT 100;

-- 8. Представление: ближайшие брони с полной информацией
EXPLAIN ANALYZE
SELECT * FROM upcoming_bookings LIMIT 50;

-- Примечание: 
-- Индексы уже созданы в schema.sql на колонках:
-- - bookings.client_id, photographer_id, room_id, session_date, status
-- - payments.booking_id, status
-- - equipment.room_id
-- - clients.email
-- - staff.email
--
-- Эти индексы должны значительно улучшить производительность запросов выше.
-- Типичное улучшение: от seq scan (полное сканирование таблицы) 
-- к index scan или index only scan.
