import io
import csv
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db

router = APIRouter(prefix="/api/import", tags=["import"])

@router.post("/clients-csv")
async def import_clients_csv(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """Импорт клиентов из CSV (columns: first_name, last_name, email, phone, is_problem_client)"""
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="File must be CSV")
    
    contents = await file.read()
    stream = io.StringIO(contents.decode('utf-8'))
    reader = csv.DictReader(stream)
    
    imported = 0
    errors = []
    
    for row in reader:
        try:
            query = text("""
                INSERT INTO clients (first_name, last_name, email, phone, is_problem_client)
                VALUES (:first_name, :last_name, :email, :phone, :is_problem_client)
            """)
            db.execute(query, {
                'first_name': row.get('first_name'),
                'last_name': row.get('last_name'),
                'email': row.get('email'),
                'phone': row.get('phone'),
                'is_problem_client': row.get('is_problem_client', 'false').lower() == 'true'
            })
            imported += 1
        except Exception as e:
            errors.append(f"Row {imported+1}: {str(e)}")
    
    db.commit()
    
    return {
        "imported": imported,
        "errors": errors,
        "message": f"Successfully imported {imported} clients"
    }

@router.post("/bookings-csv")
async def import_bookings_csv(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """Импорт броней из CSV"""
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="File must be CSV")
    
    contents = await file.read()
    stream = io.StringIO(contents.decode('utf-8'))
    reader = csv.DictReader(stream)
    
    imported = 0
    errors = []
    
    for row in reader:
        try:
            query = text("""
                INSERT INTO bookings 
                (client_id, room_id, photographer_id, tariff_package_id, session_date, 
                 session_start_time, session_end_time, total_price, status, notes)
                VALUES (:client_id, :room_id, :photographer_id, :tariff_package_id, 
                        :session_date, :session_start_time, :session_end_time, :total_price, :status, :notes)
            """)
            db.execute(query, {
                'client_id': int(row.get('client_id')),
                'room_id': int(row.get('room_id')),
                'photographer_id': int(row.get('photographer_id')),
                'tariff_package_id': int(row.get('tariff_package_id')),
                'session_date': row.get('session_date'),
                'session_start_time': row.get('session_start_time'),
                'session_end_time': row.get('session_end_time'),
                'total_price': float(row.get('total_price')),
                'status': row.get('status', 'new'),
                'notes': row.get('notes')
            })
            imported += 1
        except Exception as e:
            errors.append(f"Row {imported+1}: {str(e)}")
    
    db.commit()
    
    return {
        "imported": imported,
        "errors": errors,
        "message": f"Successfully imported {imported} bookings"
    }
