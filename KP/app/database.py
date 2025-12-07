import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

# Загружаем переменные из .env
load_dotenv()

# Берём строку подключения из .env
DATABASE_URL = os.getenv("DATABASE_URL")

# Создаём движок SQLAlchemy
engine = create_engine(
    DATABASE_URL,
    echo=True,  # Печатает все SQL-запросы в консоль (удалишь потом)
)

# Сессия для работы с БД
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

# Базовый класс для всех моделей
Base = declarative_base()

# Функция для получения сессии (будешь использовать в API)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
