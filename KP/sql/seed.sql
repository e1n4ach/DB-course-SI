-- Вставка клиентов
INSERT INTO clients (first_name, last_name, email, phone, is_problem_client, notes) VALUES
('Иван', 'Петров', 'ivan.petrov@email.com', '+79991234567', FALSE, 'VIP клиент'),
('Мария', 'Сидорова', 'maria.sidorova@email.com', '+79992345678', FALSE, NULL),
('Алексей', 'Иванов', 'alexey.ivanov@email.com', '+79993456789', TRUE, 'Часто переносит сессии'),
('Елена', 'Смирнова', 'elena.smirnova@email.com', '+79994567890', FALSE, NULL),
('Дмитрий', 'Федоров', 'dmitry.fedorov@email.com', '+79995678901', FALSE, 'Корпоративный клиент'),
('Анна', 'Морозова', 'anna.morozova@email.com', '+79996789012', FALSE, NULL),
('Сергей', 'Козлов', 'sergey.kozlov@email.com', '+79997890123', TRUE, 'Задолженность'),
('Ольга', 'Волкова', 'olga.volkova@email.com', '+79998901234', FALSE, NULL),
('Павел', 'Соколов', 'pavel.sokolov@email.com', '+79999012345', FALSE, 'Частый клиент'),
('Наталья', 'Лебедева', 'natalia.lebedeva@email.com', '+79990123456', FALSE, NULL);

-- Вставка сотрудников
INSERT INTO staff (first_name, last_name, email, phone, role, hourly_rate, is_active) VALUES
('Александр', 'Петровский', 'alex.petrovsky@studio.com', '+79991111111', 'photographer', 3000, TRUE),
('Борис', 'Сергеев', 'boris.sergeev@studio.com', '+79992222222', 'photographer', 2500, TRUE),
('Виктория', 'Романова', 'victoria.romanova@studio.com', '+79993333333', 'makeup_artist', 1500, TRUE),
('Галина', 'Никитина', 'galina.nikitina@studio.com', '+79994444444', 'makeup_artist', 1800, TRUE),
('Дарья', 'Соколова', 'darya.sokolova@studio.com', '+79995555555', 'admin', 2000, TRUE);

-- Вставка залов студии
INSERT INTO studio_rooms (name, capacity, base_equipment, status, hourly_rate) VALUES
('Белый зал', 10, 'фон, софиты, рефлекторы', 'available', 2000),
('Чёрный студио', 8, 'чёрный фон, кольцевой свет', 'available', 2500),
('Предметный уголок', 4, 'стол, предметный фон', 'available', 1500),
('Окно студии', 6, 'естественное освещение', 'maintenance', 1800);

-- Вставка оборудования
INSERT INTO equipment (name, equipment_type, serial_number, status, room_id, purchase_date, last_maintenance) VALUES
('Canon EOS R5', 'camera', 'CE123456', 'working', 1, '2022-01-15', '2025-11-01'),
('Sony A7IV', 'camera', 'SA234567', 'working', 2, '2021-06-20', '2025-10-15'),
('Canon RF 24-70mm', 'lens', 'CL345678', 'working', 1, '2022-01-15', '2025-10-01'),
('Sony FE 70-200mm', 'lens', 'SL456789', 'working', 2, '2021-06-20', '2025-09-15'),
('Godox SL-200W', 'light', 'GL567890', 'working', 1, '2020-03-10', '2025-08-01'),
('Neewer 2x3m фон', 'backdrop', 'BK678901', 'working', 1, '2021-12-05', NULL),
('Manfrotto штатив', 'tripod', 'TR789012', 'working', 2, '2022-05-20', '2025-07-01'),
('Reflector 110cm', 'reflector', 'RF890123', 'working', 3, '2021-08-30', NULL);

-- Вставка тарифных пакетов
INSERT INTO tariff_packages (name, session_type, duration_minutes, base_price, included_photos, included_edits, description) VALUES
('Семейная сессия', 'family', 120, 8000, 150, 50, 'Съёмка семьи 2-4 человека'),
('Портретная сессия', 'portrait', 60, 5000, 80, 30, 'Индивидуальный портрет'),
('Предметная фотография', 'product', 120, 6000, 100, 40, 'Съёмка товаров для интернет-магазина'),
('Love Story', 'love_story', 180, 12000, 250, 100, 'Фотосессия для молодожёнов'),
('Корпоративное событие', 'event', 480, 25000, 500, 150, 'Съёмка деловых событий');

-- Вставка дополнительных услуг
INSERT INTO additional_services (name, service_type, price, description) VALUES
('Профессиональный макияж', 'makeup', 2000, 'Работа визажиста перед съёмкой'),
('Печать фотографий (10 шт)', 'printing', 1500, 'Печать на профессиональной бумаге'),
('Реквизит дополнительный', 'props', 1000, 'Аренда реквизита для съёмки'),
('Фотоальбом 20x20см', 'album', 3000, 'Красивый фотоальбом с выбранными фото'),
('Ретушь (5 фото)', 'retouching', 1500, 'Профессиональная ретушь выбранных фото');

-- Вставка броней
INSERT INTO bookings (client_id, room_id, photographer_id, tariff_package_id, session_date, session_start_time, session_end_time, total_price, status, notes) VALUES
(1, 1, 1, 1, '2025-12-15', '10:00', '12:00', 8000, 'confirmed', 'VIP сессия'),
(2, 2, 2, 2, '2025-12-16', '14:00', '15:00', 5000, 'confirmed', NULL),
(3, 1, 1, 3, '2025-12-17', '11:00', '13:00', 6000, 'new', NULL),
(4, 3, 2, 2, '2025-12-18', '15:00', '16:00', 5000, 'confirmed', NULL),
(5, 2, 1, 5, '2025-12-20', '10:00', '14:00', 25000, 'new', 'Корпоративное событие'),
(6, 1, 2, 1, '2025-12-21', '12:00', '14:00', 8000, 'confirmed', NULL),
(7, 3, 1, 4, '2025-12-22', '16:00', '19:00', 12000, 'cancelled', 'Клиент отменил'),
(8, 2, 2, 2, '2025-12-23', '10:00', '11:00', 5000, 'new', NULL),
(9, 1, 1, 1, '2025-12-24', '14:00', '16:00', 8000, 'confirmed', NULL),
(10, 3, 2, 3, '2025-12-25', '11:00', '13:00', 6000, 'new', NULL);

-- Вставка услуг в брони
INSERT INTO booking_services (booking_id, service_id, quantity, service_price) VALUES
(1, 1, 1, 2000),
(1, 4, 1, 3000),
(2, 1, 1, 2000),
(3, 2, 2, 3000),
(4, 1, 1, 2000),
(5, 1, 3, 6000),
(6, 4, 1, 3000),
(8, 2, 2, 3000),
(9, 1, 1, 2000),
(10, 5, 1, 1500);

-- Вставка платежей
INSERT INTO payments (booking_id, amount, payment_method, payment_date, status) VALUES
(1, 13000, 'card', '2025-12-10', 'completed'),
(2, 7000, 'transfer', '2025-12-10', 'completed'),
(3, 6000, 'cash', '2025-12-17', 'pending'),
(4, 7000, 'card', '2025-12-15', 'completed'),
(5, 31000, 'transfer', '2025-12-18', 'pending'),
(6, 11000, 'card', '2025-12-20', 'completed'),
(8, 8000, 'cash', '2025-12-23', 'pending'),
(9, 10000, 'card', '2025-12-20', 'completed'),
(10, 7500, 'transfer', '2025-12-25', 'pending');
