-- Таблица клиентов
CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    is_problem_client BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица сотрудников
CREATE TABLE IF NOT EXISTS staff (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL CHECK (role IN ('photographer', 'makeup_artist', 'admin')),
    hourly_rate DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица залов студии
CREATE TABLE IF NOT EXISTS studio_rooms (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    capacity INT NOT NULL,
    base_equipment TEXT,
    status VARCHAR(50) NOT NULL CHECK (status IN ('available', 'maintenance', 'closed')) DEFAULT 'available',
    hourly_rate DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица оборудования
CREATE TABLE IF NOT EXISTS equipment (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    equipment_type VARCHAR(50) NOT NULL CHECK (equipment_type IN ('camera', 'lens', 'light', 'tripod', 'reflector', 'backdrop', 'other')),
    serial_number VARCHAR(100) UNIQUE,
    status VARCHAR(50) NOT NULL CHECK (status IN ('working', 'maintenance', 'broken')) DEFAULT 'working',
    room_id INT REFERENCES studio_rooms(id),
    purchase_date DATE,
    last_maintenance DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица тарифных пакетов
CREATE TABLE IF NOT EXISTS tariff_packages (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    session_type VARCHAR(50) NOT NULL CHECK (session_type IN ('family', 'product', 'love_story', 'portrait', 'event')),
    duration_minutes INT NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL CHECK (base_price > 0),
    included_photos INT,
    included_edits INT,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица дополнительных услуг
CREATE TABLE IF NOT EXISTS additional_services (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    service_type VARCHAR(50) NOT NULL CHECK (service_type IN ('makeup', 'printing', 'props', 'album', 'retouching', 'other')),
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    description TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица броней фотосессий
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
    room_id INT NOT NULL REFERENCES studio_rooms(id) ON DELETE RESTRICT,
    photographer_id INT NOT NULL REFERENCES staff(id) ON DELETE RESTRICT,
    tariff_package_id INT NOT NULL REFERENCES tariff_packages(id) ON DELETE RESTRICT,
    session_date DATE NOT NULL,
    session_start_time TIME NOT NULL,
    session_end_time TIME NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL CHECK (total_price > 0),
    status VARCHAR(50) NOT NULL CHECK (status IN ('new', 'confirmed', 'cancelled', 'completed')) DEFAULT 'new',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица услуг в брони (связь N:M)
CREATE TABLE IF NOT EXISTS booking_services (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    service_id INT NOT NULL REFERENCES additional_services(id) ON DELETE RESTRICT,
    quantity INT NOT NULL DEFAULT 1,
    service_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица платежей
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('cash', 'card', 'transfer')),
    payment_date TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'completed', 'refunded')) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица обслуживания оборудования
CREATE TABLE IF NOT EXISTS maintenance_log (
    id SERIAL PRIMARY KEY,
    equipment_id INT NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    maintenance_type VARCHAR(50) NOT NULL CHECK (maintenance_type IN ('repair', 'cleaning', 'inspection', 'calibration')),
    description TEXT,
    cost DECIMAL(10, 2),
    maintenance_date DATE NOT NULL,
    next_maintenance_date DATE,
    performed_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица журнала аудита
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id INT NOT NULL,
    changed_by VARCHAR(100),
    old_values JSONB,
    new_values JSONB,
    change_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Индексы для оптимизации
CREATE INDEX idx_bookings_client_id ON bookings(client_id);
CREATE INDEX idx_bookings_photographer_id ON bookings(photographer_id);
CREATE INDEX idx_bookings_room_id ON bookings(room_id);
CREATE INDEX idx_bookings_session_date ON bookings(session_date);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_equipment_room_id ON equipment(room_id);
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_staff_email ON staff(email);
