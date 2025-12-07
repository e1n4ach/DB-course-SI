from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import schemas, crud

router = APIRouter(prefix="/api/rooms", tags=["rooms"])

@router.get("/", response_model=list[schemas.StudioRoom])
def list_rooms(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Получить список всех залов"""
    rooms = crud.get_studio_rooms(db, skip=skip, limit=limit)
    return rooms

@router.get("/available", response_model=list[schemas.StudioRoom])
def get_available_rooms(db: Session = Depends(get_db)):
    """Получить доступные залы"""
    rooms = crud.get_available_rooms(db)
    return rooms

@router.get("/{room_id}", response_model=schemas.StudioRoom)
def get_room(room_id: int, db: Session = Depends(get_db)):
    """Получить зал по ID"""
    room = crud.get_studio_room(db, room_id)
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    return room
