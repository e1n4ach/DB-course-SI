from sqlalchemy.orm import Session
from app import models, schemas

# ============= CLIENT CRUD =============
def get_client(db: Session, client_id: int):
    """Получить клиента по ID"""
    return db.query(models.Client).filter(models.Client.id == client_id).first()

def get_clients(db: Session, skip: int = 0, limit: int = 100):
    """Получить список клиентов"""
    return db.query(models.Client).offset(skip).limit(limit).all()

def create_client(db: Session, client: schemas.ClientCreate):
    """Создать нового клиента"""
    db_client = models.Client(**client.dict())
    db.add(db_client)
    db.commit()
    db.refresh(db_client)
    return db_client

def update_client(db: Session, client_id: int, client_update: schemas.ClientUpdate):
    """Обновить клиента"""
    db_client = get_client(db, client_id)
    if not db_client:
        return None
    update_data = client_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_client, field, value)
    db.commit()
    db.refresh(db_client)
    return db_client

def delete_client(db: Session, client_id: int):
    """Удалить клиента"""
    db_client = get_client(db, client_id)
    if db_client:
        db.delete(db_client)
        db.commit()
    return db_client

# ============= BOOKING CRUD =============
def get_booking(db: Session, booking_id: int):
    """Получить бронь по ID"""
    return db.query(models.Booking).filter(models.Booking.id == booking_id).first()

def get_bookings(db: Session, skip: int = 0, limit: int = 100):
    """Получить список броней"""
    return db.query(models.Booking).offset(skip).limit(limit).all()

def get_bookings_by_status(db: Session, status: str, skip: int = 0, limit: int = 100):
    """Получить брони по статусу"""
    return db.query(models.Booking).filter(models.Booking.status == status).offset(skip).limit(limit).all()

def create_booking(db: Session, booking: schemas.BookingCreate):
    """Создать новую бронь"""
    db_booking = models.Booking(**booking.dict())
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    return db_booking

def update_booking(db: Session, booking_id: int, booking_update: schemas.BookingUpdate):
    """Обновить бронь"""
    db_booking = get_booking(db, booking_id)
    if not db_booking:
        return None
    update_data = booking_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_booking, field, value)
    db.commit()
    db.refresh(db_booking)
    return db_booking

def delete_booking(db: Session, booking_id: int):
    """Удалить бронь"""
    db_booking = get_booking(db, booking_id)
    if db_booking:
        db.delete(db_booking)
        db.commit()
    return db_booking

# ============= STAFF CRUD =============
def get_staff(db: Session, staff_id: int):
    """Получить сотрудника по ID"""
    return db.query(models.Staff).filter(models.Staff.id == staff_id).first()

def get_staff_list(db: Session, skip: int = 0, limit: int = 100):
    """Получить список сотрудников"""
    return db.query(models.Staff).offset(skip).limit(limit).all()

def create_staff(db: Session, staff: schemas.StaffCreate):
    """Создать нового сотрудника"""
    db_staff = models.Staff(**staff.dict())
    db.add(db_staff)
    db.commit()
    db.refresh(db_staff)
    return db_staff

# ============= STUDIO ROOM CRUD =============
def get_studio_room(db: Session, room_id: int):
    """Получить зал по ID"""
    return db.query(models.StudioRoom).filter(models.StudioRoom.id == room_id).first()

def get_studio_rooms(db: Session, skip: int = 0, limit: int = 100):
    """Получить список залов"""
    return db.query(models.StudioRoom).offset(skip).limit(limit).all()

def get_available_rooms(db: Session):
    """Получить доступные залы"""
    return db.query(models.StudioRoom).filter(models.StudioRoom.status == 'available').all()

# ============= TARIFF PACKAGE CRUD =============
def get_tariff_package(db: Session, package_id: int):
    """Получить тариф по ID"""
    return db.query(models.TariffPackage).filter(models.TariffPackage.id == package_id).first()

def get_tariff_packages(db: Session, skip: int = 0, limit: int = 100):
    """Получить список тарифов"""
    return db.query(models.TariffPackage).filter(models.TariffPackage.is_active == True).offset(skip).limit(limit).all()
