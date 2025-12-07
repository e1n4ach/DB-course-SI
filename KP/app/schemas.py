from pydantic import BaseModel, EmailStr
from datetime import datetime, date, time
from typing import Optional

# ============= CLIENT SCHEMAS =============
class ClientBase(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    phone: str
    is_problem_client: bool = False
    notes: Optional[str] = None

class ClientCreate(ClientBase):
    pass

class ClientUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    is_problem_client: Optional[bool] = None
    notes: Optional[str] = None

class Client(ClientBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ============= BOOKING SCHEMAS =============
class BookingBase(BaseModel):
    client_id: int
    room_id: int
    photographer_id: int
    tariff_package_id: int
    session_date: date
    session_start_time: time
    session_end_time: time
    total_price: float
    status: str = "new"
    notes: Optional[str] = None

class BookingCreate(BookingBase):
    pass

class BookingUpdate(BaseModel):
    status: Optional[str] = None
    total_price: Optional[float] = None
    notes: Optional[str] = None

class Booking(BookingBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ============= STAFF SCHEMAS =============
class StaffBase(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    phone: Optional[str] = None
    role: str
    hourly_rate: float
    is_active: bool = True

class StaffCreate(StaffBase):
    pass

class Staff(StaffBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ============= STUDIO ROOM SCHEMAS =============
class StudioRoomBase(BaseModel):
    name: str
    capacity: int
    base_equipment: Optional[str] = None
    status: str = "available"
    hourly_rate: float

class StudioRoomCreate(StudioRoomBase):
    pass

class StudioRoom(StudioRoomBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ============= TARIFF PACKAGE SCHEMAS =============
class TariffPackageBase(BaseModel):
    name: str
    session_type: str
    duration_minutes: int
    base_price: float
    included_photos: Optional[int] = None
    included_edits: Optional[int] = None
    description: Optional[str] = None
    is_active: bool = True

class TariffPackageCreate(TariffPackageBase):
    pass

class TariffPackage(TariffPackageBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
