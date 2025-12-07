# Photo Studio Management System - Database Course Project

Информационная система управления фотостудией и бронированием фотосессий.

## 📋 Описание проекта

Платформа для управления:
- **Клиентами** — профили, контакты, отметки о проблемных клиентах
- **Расписанием фотосессий** — бронирование, статусы (новая, подтверждена, отменена, завершена)
- **Залами и оборудованием** — управление ресурсами, учёт обслуживания
- **Фотографами и сотрудниками** — расписание, ставки, роли
- **Тарифными пакетами** — типы съёмки, цены, дополнительные услуги
- **Платежами** — отслеживание оплат и статусы

**Стек технологий:**
- **БД:** PostgreSQL 13+
- **Backend:** Python 3.10+, FastAPI, SQLAlchemy ORM
- **Контейнеризация:** Docker, docker-compose
- **Документация API:** Swagger/OpenAPI

---

## 🚀 Быстрый старт

### Требования
- Docker & docker-compose
- Git

### Установка и запуск

**1. Клонируй репозиторий:**
git clone https://github.com/e1n4ach/DB-course-SI.git
cd DB-course-SI/KP

**2. Запусти контейнеры:**
docker-compose up -d


Это запустит:
- PostgreSQL на `localhost:5432`
- FastAPI на `http://localhost:8000`

**3. Инициализация БД (выполняется автоматически):**

Скрипты загружаются в порядке:
1. `sql/schema.sql` — создание таблиц и ограничений
2. `sql/functions.sql` — функции, представления, триггеры
3. `sql/seed.sql` — тестовые данные
4. `sql/explain_analyze.sql` — примеры EXPLAIN ANALYZE

Если нужно загрузить вручную:
docker exec -i photostudio-db psql -U postgres -d photostudio < sql/schema.sql
docker exec -i photostudio-db psql -U postgres -d photostudio < sql/functions.sql
docker exec -i photostudio-db psql -U postgres -d photostudio < sql/seed.sql


**4. Проверь здоровье сервиса:**
curl http://localhost:8000/health

Результат: {"status":"ok"}


---

## 📚 API Документация

**Swagger UI:** [http://localhost:8000/docs](http://localhost:8000/docs)

### Основные эндпоинты

#### Клиенты
- `GET /api/clients/` — список всех клиентов
- `POST /api/clients/` — создать клиента
- `GET /api/clients/{id}` — получить клиента по ID
- `PUT /api/clients/{id}` — обновить клиента
- `DELETE /api/clients/{id}` — удалить клиента

#### Брони (Bookings)
- `GET /api/bookings/` — список всех броней
- `POST /api/bookings/` — создать бронь
- `GET /api/bookings/status/{status}` — брони по статусу (new, confirmed, completed, cancelled)
- `GET /api/bookings/{id}` — получить бронь по ID
- `PUT /api/bookings/{id}` — обновить бронь
- `DELETE /api/bookings/{id}` — удалить бронь

#### Залы (Rooms)
- `GET /api/rooms/` — список всех залов
- `GET /api/rooms/available` — только доступные залы
- `GET /api/rooms/{id}` — получить зал по ID

#### Отчёты (Reports)
- `GET /api/reports/photographer-income?start_date=2025-12-01&end_date=2025-12-31` — выручка по фотографам
- `GET /api/reports/room-usage?start_date=2025-12-01&end_date=2025-12-31` — загруженность залов
- `GET /api/reports/problem-clients` — статистика проблемных клиентов
- `GET /api/reports/upcoming-bookings` — ближайшие брони
- `GET /api/reports/room-revenue` — выручка по залам
- `GET /api/reports/popular-packages` — популярные пакеты
- `GET /api/reports/audit-log?limit=100` — журнал аудита

#### Импорт данных
- `POST /api/import/clients-csv` — импорт клиентов из CSV
- `POST /api/import/bookings-csv` — импорт броней из CSV





(venv) levian@DESKTOP-DFOO1AK:/mnt/c/Users/levi/programming/DB-course-SI/KP$ docker exec photostudio-db psql -U postgres -d photostudio << 'SQL'
> -- Проверка целостности данных
 'Book> SELECT
>     'Bookings with valid clients' as check_name,
DISTINC>     COUNT(DISTINCT b.client_id) as count
 b
JOIN > FROM bookings b
c ON b.c> JOIN clients c ON b.client_id = c.id;

SELECT >
> SELECT
Bookings>     'Bookings with valid photographers' as check_name,
NT(DIST>     COUNT(DISTINCT b.photographer_id) as count
> FROM bookings b
 staff s> JOIN staff s ON b.photographer_id = s.id;
>
> SELECT
>     'Bookings with valid rooms' as check_name,
>     COUNT(DISTINCT b.room_id) as count
ROM bookings b
J> FROM bookings b
> JOIN studio_rooms r ON b.room_id = r.id;
   'Eq>
uipmen> SELECT
>     'Equipment with valid rooms' as check_name,
>     COUNT(DISTINCT e.room_id) as count
> FROM equipment e
> JOIN studio_rooms r ON e.room_id = r.id
> WHERE e.room_id IS NOT NULL;
>
> SELECT
>     'Payments linked to bookings' as check_name,
>     COUNT(DISTINCT p.booking_id) as count
ayments > FROM payments p
> JOIN bookings b ON p.booking_id = b.id;
> SQL
(venv) levian@DESKTOP-DFOO1AK:/mnt/c/Users/levi/programming/DB-course-SI/KP$ docker exec photostudio-db psql -U postgres -d photostudio -c "
ECT 'B> SELECT 'Bookings with valid clients' as check_name, COUNT(DISTINCT b.client_id) as count FROM bookings b JOIN clients c ON b.client_id = c.id;
'Booking> SELECT 'Bookings with valid photographers', COUNT(DISTINCT b.photographer_id) FROM bookings b JOIN staff s ON b.photographer_id = s.id;
> SELECT 'Bookings with valid rooms', COUNT(DISTINCT b.room_id) FROM bookings b JOIN studio_rooms r ON b.room_id = r.id;
> SELECT 'Equipment with valid rooms', COUNT(DISTINCT e.room_id) FROM equipment e JOIN studio_rooms r ON e.room_id = r.id WHERE e.room_id IS NOT NULL;
> SELECT 'Payments linked to bookings', COUNT(DISTINCT p.booking_id) FROM payments p JOIN bookings b ON p.booking_id = b.id;
> "
         check_name          | count 
-----------------------------+-------
 Bookings with valid clients |   100
(1 row)

             ?column?              | count
-----------------------------------+-------
 Bookings with valid photographers |    20
(1 row)

         ?column?          | count
---------------------------+-------
 Bookings with valid rooms |     8
(1 row)

          ?column?          | count
----------------------------+-------
 Equipment with valid rooms |     8
(1 row)

          ?column?           | count 
-----------------------------+-------
 Payments linked to bookings |   250
(1 row)

(venv) levian@DESKTOP-DFOO1AK:/mnt/c/Users/levi/programming/DB-course-SI/KP$ docker exec photostudio-db psql -U postgres -d photostudio -c "
ample Bo> SELECT 'Sample Bookings' as section;
first_n> SELECT b.id, c.first_name, s.first_name as photographer, r.name as room, b.session_date, b.total_price 
 booking> FROM bookings b
> JOIN clients c ON b.client_id = c.id 
aff s ON> JOIN staff s ON b.photographer_id = s.id 
ms r ON > JOIN studio_rooms r ON b.room_id = r.id
> LIMIT 5;
>
> SELECT '' as blank;
> SELECT 'Sample Equipment' as section;
CT e.id,> SELECT e.id, e.name, e.equipment_type, e.status, r.name as room 
quipment> FROM equipment e
> JOIN studio_rooms r ON e.room_id = r.id 
> LIMIT 5;
>
> SELECT '' as blank;
> SELECT 'Sample Payments' as section;
> SELECT p.id, b.id as booking_id, p.amount, p.payment_method, p.status 
> FROM payments p
> JOIN bookings b ON p.booking_id = b.id 
> LIMIT 5;
> "
     section     
-----------------
 Sample Bookings
(1 row)

 id | first_name | photographer |   room   | session_date | total_price
----+------------+--------------+----------+--------------+-------------
  1 | Client2    | Staff2       | Studio B | 2025-12-08   |     5100.00
  2 | Client3    | Staff3       | Studio C | 2025-12-09   |     5200.00
  3 | Client4    | Staff4       | Studio D | 2025-12-10   |     5300.00
  4 | Client5    | Staff5       | Studio E | 2025-12-11   |     5400.00
  5 | Client6    | Staff6       | Studio F | 2025-12-12   |     5500.00
(5 rows)

 blank
-------

(1 row)

     section
------------------
 Sample Equipment
(1 row)

 id |    name     | equipment_type |   status    |   room
----+-------------+----------------+-------------+----------
  1 | Equipment 1 | lens           | maintenance | Studio B
  2 | Equipment 2 | light          | broken      | Studio C
  3 | Equipment 3 | tripod         | working     | Studio D
  4 | Equipment 4 | reflector      | maintenance | Studio E
  5 | Equipment 5 | backdrop       | broken      | Studio F
(5 rows)

 blank
-------

(1 row)

     section
-----------------
 Sample Payments
(1 row)

 id | booking_id | amount  | payment_method |  status
----+------------+---------+----------------+-----------
  1 |          2 | 5050.00 | cash           | pending
  2 |          3 | 5100.00 | transfer       | completed
  3 |          4 | 5150.00 | card           | pending
  4 |          5 | 5200.00 | cash           | completed
  5 |          6 | 5250.00 | transfer       | pending
(5 rows)
