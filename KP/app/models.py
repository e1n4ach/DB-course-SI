from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, Float, Date, Time, Numeric, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.database import Base

class Client(Base):
    __tablename__ = "clients"
    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False, index=True)
    phone = Column(String(20), nullable=False)
    is_problem_client = Column(Boolean, default=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

class Staff(Base):
    __tablename__ = "staff"
    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False, index=True)
    phone = Column(String(20), nullable=True)
    role = Column(String(50), nullable=False)
    hourly_rate = Column(Numeric(10, 2), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

class StudioRoom(Base):
    __tablename__ = "studio_rooms"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    capacity = Column(Integer, nullable=False)
    base_equipment = Column(Text, nullable=True)
    status = Column(String(50), default='available')
    hourly_rate = Column(Numeric(10, 2), nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

class Equipment(Base):
    __tablename__ = "equipment"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    equipment_type = Column(String(50), nullable=False)
    serial_number = Column(String(100), unique=True, nullable=True)
    status = Column(String(50), default='working')
    room_id = Column(Integer, ForeignKey('studio_rooms.id'), nullable=True)
    purchase_date = Column(Date, nullable=True)
    last_maintenance = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

class TariffPackage(Base):
    __tablename__ = "tariff_packages"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    session_type = Column(String(50), nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    base_price = Column(Numeric(10, 2), nullable=False)
    included_photos = Column(Integer, nullable=True)
    included_edits = Column(Integer, nullable=True)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

class AdditionalService(Base):
    __tablename__ = "additional_services"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    service_type = Column(String(50), nullable=False)
    price = Column(Numeric(10, 2), nullable=False)
    description = Column(Text, nullable=True)
    is_available = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

class Booking(Base):
    __tablename__ = "bookings"
    id = Column(Integer, primary_key=True, index=True)
    client_id = Column(Integer, ForeignKey('clients.id'), nullable=False)
    room_id = Column(Integer, ForeignKey('studio_rooms.id'), nullable=False)
    photographer_id = Column(Integer, ForeignKey('staff.id'), nullable=False)
    tariff_package_id = Column(Integer, ForeignKey('tariff_packages.id'), nullable=False)
    session_date = Column(Date, nullable=False)
    session_start_time = Column(Time, nullable=False)
    session_end_time = Column(Time, nullable=False)
    total_price = Column(Numeric(10, 2), nullable=False)
    status = Column(String(50), default='new')
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

class BookingService(Base):
    __tablename__ = "booking_services"
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey('bookings.id'), nullable=False)
    service_id = Column(Integer, ForeignKey('additional_services.id'), nullable=False)
    quantity = Column(Integer, default=1)
    service_price = Column(Numeric(10, 2), nullable=False)
    created_at = Column(DateTime, server_default=func.now())

class Payment(Base):
    __tablename__ = "payments"
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey('bookings.id'), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    payment_method = Column(String(50), nullable=False)
    payment_date = Column(DateTime, nullable=False)
    status = Column(String(50), default='pending')
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

class MaintenanceLog(Base):
    __tablename__ = "maintenance_log"
    id = Column(Integer, primary_key=True, index=True)
    equipment_id = Column(Integer, ForeignKey('equipment.id'), nullable=False)
    maintenance_type = Column(String(50), nullable=False)
    description = Column(Text, nullable=True)
    cost = Column(Numeric(10, 2), nullable=True)
    maintenance_date = Column(Date, nullable=False)
    next_maintenance_date = Column(Date, nullable=True)
    performed_by = Column(String(100), nullable=True)
    created_at = Column(DateTime, server_default=func.now())

class AuditLog(Base):
    __tablename__ = "audit_log"
    id = Column(Integer, primary_key=True, index=True)
    table_name = Column(String(100), nullable=False)
    operation = Column(String(10), nullable=False)
    record_id = Column(Integer, nullable=False)
    changed_by = Column(String(100), nullable=True)
    old_values = Column(JSONB, nullable=True)
    new_values = Column(JSONB, nullable=True)
    change_timestamp = Column(DateTime, server_default=func.now())
