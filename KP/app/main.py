from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import clients, bookings, reports, import_data, rooms

app = FastAPI(
    title="Photo Studio Management API",
    description="API для управления фотостудией и бронированием фотосессий",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем маршруты
app.include_router(clients.router)
app.include_router(bookings.router)
app.include_router(reports.router)
app.include_router(import_data.router)
app.include_router(rooms.router)

@app.get("/")
def read_root():
    """Проверка, что API живёт"""
    return {
        "message": "Photo Studio API is running!",
        "docs": "/docs",
    }

@app.get("/health")
def health_check():
    """Проверка здоровья сервиса"""
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
