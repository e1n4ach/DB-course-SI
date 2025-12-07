from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import schemas, crud

router = APIRouter(prefix="/api/bookings", tags=["bookings"])

@router.get("/", response_model=list[schemas.Booking])
def list_bookings(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Получить список всех броней"""
    bookings = crud.get_bookings(db, skip=skip, limit=limit)
    return bookings

@router.get("/status/{status}", response_model=list[schemas.Booking])
def get_bookings_by_status(status: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Получить брони по статусу (new, confirmed, cancelled, completed)"""
    bookings = crud.get_bookings_by_status(db, status, skip=skip, limit=limit)
    return bookings

@router.get("/{booking_id}", response_model=schemas.Booking)
def get_booking(booking_id: int, db: Session = Depends(get_db)):
    """Получить бронь по ID"""
    booking = crud.get_booking(db, booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking

@router.post("/", response_model=schemas.Booking)
def create_booking(booking: schemas.BookingCreate, db: Session = Depends(get_db)):
    """Создать новую бронь"""
    return crud.create_booking(db, booking)

@router.put("/{booking_id}", response_model=schemas.Booking)
def update_booking(booking_id: int, booking: schemas.BookingUpdate, db: Session = Depends(get_db)):
    """Обновить статус брони"""
    updated_booking = crud.update_booking(db, booking_id, booking)
    if not updated_booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return updated_booking

@router.delete("/{booking_id}")
def delete_booking(booking_id: int, db: Session = Depends(get_db)):
    """Удалить бронь"""
    deleted = crud.delete_booking(db, booking_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Booking not found")
    return {"message": "Booking deleted successfully"}
