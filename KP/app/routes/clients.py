from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app import schemas, crud

router = APIRouter(prefix="/api/clients", tags=["clients"])

@router.get("/", response_model=list[schemas.Client])
def list_clients(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Получить список всех клиентов"""
    clients = crud.get_clients(db, skip=skip, limit=limit)
    return clients

@router.get("/{client_id}", response_model=schemas.Client)
def get_client(client_id: int, db: Session = Depends(get_db)):
    """Получить клиента по ID"""
    client = crud.get_client(db, client_id)
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")
    return client

@router.post("/", response_model=schemas.Client)
def create_client(client: schemas.ClientCreate, db: Session = Depends(get_db)):
    """Создать нового клиента"""
    return crud.create_client(db, client)

@router.put("/{client_id}", response_model=schemas.Client)
def update_client(client_id: int, client: schemas.ClientUpdate, db: Session = Depends(get_db)):
    """Обновить данные клиента"""
    updated_client = crud.update_client(db, client_id, client)
    if not updated_client:
        raise HTTPException(status_code=404, detail="Client not found")
    return updated_client

@router.delete("/{client_id}")
def delete_client(client_id: int, db: Session = Depends(get_db)):
    """Удалить клиента"""
    deleted = crud.delete_client(db, client_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Client not found")
    return {"message": "Client deleted successfully"}
