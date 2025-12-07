from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.database import get_db
from datetime import date

router = APIRouter(prefix="/api/reports", tags=["reports"])

@router.get("/photographer-income")
def get_photographer_income(
    start_date: date = Query(..., description="Start date (YYYY-MM-DD)"),
    end_date: date = Query(..., description="End date (YYYY-MM-DD)"),
    db: Session = Depends(get_db)
):
    """Выручка по фотографам за период"""
    query = text("""
        SELECT * FROM get_photographer_income(:start_date, :end_date)
    """)
    result = db.execute(query, {"start_date": start_date, "end_date": end_date})
    return [dict(row._mapping) for row in result]

@router.get("/room-usage")
def get_room_usage(
    start_date: date = Query(..., description="Start date (YYYY-MM-DD)"),
    end_date: date = Query(..., description="End date (YYYY-MM-DD)"),
    db: Session = Depends(get_db)
):
    """Загруженность залов по дням"""
    query = text("""
        SELECT * FROM get_room_usage(:start_date, :end_date)
    """)
    result = db.execute(query, {"start_date": start_date, "end_date": end_date})
    return [dict(row._mapping) for row in result]

@router.get("/problem-clients")
def get_problem_clients(db: Session = Depends(get_db)):
    """Статистика проблемных клиентов"""
    query = text("SELECT * FROM get_problem_clients_stats()")
    result = db.execute(query)
    return [dict(row._mapping) for row in result]

@router.get("/upcoming-bookings")
def get_upcoming_bookings(db: Session = Depends(get_db)):
    """Ближайшие брони"""
    query = text("SELECT * FROM upcoming_bookings LIMIT 50")
    result = db.execute(query)
    return [dict(row._mapping) for row in result]

@router.get("/room-revenue")
def get_room_revenue(db: Session = Depends(get_db)):
    """Выручка по залам"""
    query = text("SELECT * FROM room_revenue")
    result = db.execute(query)
    return [dict(row._mapping) for row in result]

@router.get("/popular-packages")
def get_popular_packages(db: Session = Depends(get_db)):
    """Топ популярные пакеты"""
    query = text("SELECT * FROM popular_packages")
    result = db.execute(query)
    return [dict(row._mapping) for row in result]

@router.get("/audit-log")
def get_audit_log(
    limit: int = Query(100, description="Max records"),
    db: Session = Depends(get_db)
):
    """Журнал аудита последних изменений"""
    query = text("""
        SELECT * FROM audit_log 
        ORDER BY change_timestamp DESC 
        LIMIT :limit
    """)
    result = db.execute(query, {"limit": limit})
    return [dict(row._mapping) for row in result]
