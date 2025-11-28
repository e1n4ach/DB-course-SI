------------------------------------------------------------
-- 1. ИНДЕКСЫ И ПРОСТОЙ АНАЛИЗ ЧЕРЕЗ EXPLAIN ANALYZE
------------------------------------------------------------

-- 1.1. Поиск контента по типу и году выпуска
-- Запрос: фильтрация по типу и диапазону года + сортировка

-- Вариант запроса (можно запускать до/после создания индекса для сравнения плана):
EXPLAIN ANALYZE
SELECT content_id, title, content_type, release_year
FROM content_items
WHERE content_type = 'MOVIE'
  AND release_year BETWEEN 2000 AND 2020
ORDER BY release_year DESC;

-- Создаём комбинированный индекс по типу и году
CREATE INDEX IF NOT EXISTS idx_content_items_type_year
ON content_items(content_type, release_year);

-- Повторный запуск запроса для анализа использования индекса:
EXPLAIN ANALYZE
SELECT content_id, title, content_type, release_year
FROM content_items
WHERE content_type = 'MOVIE'
  AND release_year BETWEEN 2000 AND 2020
ORDER BY release_year DESC;


-- 1.2. Фильтрация и сортировка по языку и названию (текстовые поля)

EXPLAIN ANALYZE
SELECT content_id, title, language
FROM content_items
WHERE language = 'en'
ORDER BY title;

-- Индекс по language + title (оптимален для такого фильтра + сортировки)
CREATE INDEX IF NOT EXISTS idx_content_items_lang_title
ON content_items(language, title);

EXPLAIN ANALYZE
SELECT content_id, title, language
FROM content_items
WHERE language = 'en'
ORDER BY title;


-- 1.3. Поиск по префиксу названия (LIKE 'The%')

EXPLAIN ANALYZE
SELECT content_id, title
FROM content_items
WHERE title LIKE 'The%';

-- Для префиксного поиска LIKE 'prefix%' достаточно обычного btree-индекса
CREATE INDEX IF NOT EXISTS idx_content_items_title_prefix
ON content_items(title);

EXPLAIN ANALYZE
SELECT content_id, title
FROM content_items
WHERE title LIKE 'The%';


-- 1.4. Индекс по оценкам пользователя (частый сценарий: "мои оценки")

EXPLAIN ANALYZE
SELECT r.content_id, ci.title, r.score
FROM ratings r
JOIN content_items ci ON ci.content_id = r.content_id
WHERE r.user_id = 1
ORDER BY r.score DESC;

CREATE INDEX IF NOT EXISTS idx_ratings_user
ON ratings(user_id);

EXPLAIN ANALYZE
SELECT r.content_id, ci.title, r.score
FROM ratings r
JOIN content_items ci ON ci.content_id = r.content_id
WHERE r.user_id = 1
ORDER BY r.score DESC;



------------------------------------------------------------
-- 2. АНАЛИЗ ПРОИЗВОДИТЕЛЬНОСТИ С EXPLAIN ДЛЯ СЛОЖНЫХ ЗАПРОСОВ
------------------------------------------------------------

-- 2.1. Средний рейтинг и количество оценок по каждому контенту (JOIN + GROUP BY)

EXPLAIN ANALYZE
SELECT
  ci.content_id,
  ci.title,
  AVG(r.score)   AS avg_score,
  COUNT(r.score) AS ratings_count
FROM content_items ci
LEFT JOIN ratings r ON ci.content_id = r.content_id
GROUP BY ci.content_id, ci.title
ORDER BY avg_score DESC NULLS LAST;


-- 2.2. Количество элементов в коллекциях каждого пользователя (несколько JOIN + GROUP BY)

EXPLAIN ANALYZE
SELECT
  u.user_id,
  u.display_name,
  COUNT(ci.content_id) AS items_in_collections
FROM users u
LEFT JOIN collections c      ON u.user_id = c.user_id
LEFT JOIN collection_items ci ON c.collection_id = ci.collection_id
GROUP BY u.user_id, u.display_name
ORDER BY items_in_collections DESC;


-- 2.3. Активность пользователей: сколько списков и сколько оценок (двойной JOIN + GROUP BY)

EXPLAIN ANALYZE
SELECT
  u.user_id,
  u.display_name,
  COUNT(DISTINCT l.list_id)    AS lists_count,
  COUNT(DISTINCT r.content_id) AS ratings_count
FROM users u
LEFT JOIN lists   l ON u.user_id = l.user_id
LEFT JOIN ratings r ON u.user_id = r.user_id
GROUP BY u.user_id, u.display_name
ORDER BY ratings_count DESC, lists_count DESC;



------------------------------------------------------------
-- 3. ТРАНЗАКЦИИ И АНОМАЛИИ ПАРАЛЛЕЛЬНОГО ДОСТУПА
------------------------------------------------------------
-- Для демонстрации аномалий используем отдельную вспомогательную таблицу.
-- Логику можно запускать в двух отдельных сессиях psql (T1 и T2).

-- 3.0. Подготовка вспомогательной таблицы
CREATE TABLE IF NOT EXISTS tx_demo (
    id      BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    value   INTEGER NOT NULL
);

-- Очистим и заново заполним тестовые данные
TRUNCATE TABLE tx_demo;

INSERT INTO tx_demo(user_id, value) VALUES
  (1, 100),
  (2, 200),
  (3, 300);


------------------------------------------------------------
-- 3.1. NON-REPEATABLE READ (НЕПОВТОРЯЕМОЕ ЧТЕНИЕ)
------------------------------------------------------------
-- В PostgreSQL эта аномалия возможна на уровне изоляции READ COMMITTED.
-- Ниже сценарий для двух параллельных транзакций T1 и T2.
-- Команды помечены комментариями -- T1: ... и -- T2: ...
-- Их нужно выполнять в ДВУХ отдельных сессиях psql.

-- === Сценарий 1: Non-repeatable read (READ COMMITTED) ===
-- Уровень изоляции по умолчанию в PostgreSQL как раз READ COMMITTED.

-- T1:
-- BEGIN;
-- SELECT value FROM tx_demo WHERE id = 1;  -- допустим, вернуло 100

-- T2:
-- BEGIN;
-- UPDATE tx_demo SET value = 500 WHERE id = 1;
-- COMMIT;

-- T1:
-- SELECT value FROM tx_demo WHERE id = 1;  -- теперь вернёт 500 (значение изменилось)
-- COMMIT;

-- Комментарий:
-- В T1 одно и то же SELECT в рамках транзакции может показать разные значения.
-- Это и есть неповторяемое чтение.
--
-- Как избавиться:
-- В T1 использовать более высокий уровень изоляции, например:
--   BEGIN ISOLATION LEVEL REPEATABLE READ;
-- Тогда оба SELECT в T1 будут видеть одну и ту же "снимковую" версию данных.


------------------------------------------------------------
-- 3.2. PHANTOM READ (ФАНТОМНОЕ ЧТЕНИЕ)
------------------------------------------------------------
-- В PostgreSQL фантомы возможны на уровне READ COMMITTED.
-- Пример: T1 дважды считает количество строк по условию,
-- а T2 между этими запросами вставляет новую подходящую строку.

-- Восстановим данные:
TRUNCATE TABLE tx_demo;
INSERT INTO tx_demo(user_id, value) VALUES
  (1, 100),
  (2, 200),
  (3, 300);

-- === Сценарий 2: Phantom read (READ COMMITTED) ===

-- T1:
-- BEGIN;
-- SELECT COUNT(*) FROM tx_demo WHERE value >= 100;  -- допустим, вернуло 3

-- T2:
-- BEGIN;
-- INSERT INTO tx_demo(user_id, value) VALUES (4, 150);
-- COMMIT;

-- T1:
-- SELECT COUNT(*) FROM tx_demo WHERE value >= 100;  -- теперь вернёт 4
-- COMMIT;

-- Комментарий:
-- Во второй выборке T1 видит "нового" подходящего к условию фантомного ряда.
--
-- Как избежать:
-- Использовать уровень изоляции SERIALIZABLE в T1:
--   BEGIN ISOLATION LEVEL SERIALIZABLE;
-- При конфликте сериализации одна из транзакций будет откатана,
-- что предотвращает фантомы логически.


------------------------------------------------------------
-- 3.3. DIRTY READ (ГРЯЗНОЕ ЧТЕНИЕ)
------------------------------------------------------------
-- В классической теории dirty read = чтение НЕЗАКОММИЧЕННЫХ изменений другой транзакции.
-- PostgreSQL НЕ допускает настоящего dirty read: READ UNCOMMITTED=READ COMMITTED.
-- Поэтому мы покажем попытку грязного чтения и то, что система его предотвращает.

TRUNCATE TABLE tx_demo;
INSERT INTO tx_demo(user_id, value) VALUES
  (1, 100);

-- === Сценарий 3: Попытка dirty read ===

-- T1:
-- BEGIN;
-- UPDATE tx_demo SET value = 999 WHERE id = 1;
-- -- Транзакция пока НЕ делает COMMIT, изменения не зафиксированы.

-- T2:
-- BEGIN ISOLATION LEVEL READ UNCOMMITTED;
-- SELECT value FROM tx_demo WHERE id = 1;
-- -- В PostgreSQL здесь будет виден СТАРЫЙ value (100), а не 999.
-- -- Т.е. грязное чтение не происходит, движок защищает от него.
-- COMMIT;

-- T1:
-- ROLLBACK;  -- откатываем изменения

-- Комментарий:
-- Даже при формально указанном READ UNCOMMITTED PostgreSQL ведёт себя,
-- как READ COMMITTED, и не показывает незакоммиченные изменения.
-- Поэтому истинного dirty read в PostgreSQL нет.