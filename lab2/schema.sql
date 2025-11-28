-- 1. СОЗДАНИЕ СХЕМЫ БАЗЫ ДАННЫХ

-- снесём объекты в корректном порядке
DROP TABLE IF EXISTS list_items       CASCADE;
DROP TABLE IF EXISTS lists            CASCADE;
DROP TABLE IF EXISTS collection_items CASCADE;
DROP TABLE IF EXISTS collections      CASCADE;
DROP TABLE IF EXISTS ratings          CASCADE;
DROP TABLE IF EXISTS content_items    CASCADE;
DROP TABLE IF EXISTS users            CASCADE;

DROP TYPE IF EXISTS content_type_enum;
DROP TYPE IF EXISTS list_type_enum;

CREATE TYPE content_type_enum AS ENUM ('BOOK', 'MOVIE', 'MUSIC');
CREATE TYPE list_type_enum    AS ENUM ('READING', 'WATCHING', 'LISTENING', 'CUSTOM');

-- Пользователи
CREATE TABLE users (
  user_id       BIGSERIAL PRIMARY KEY,
  email         VARCHAR(320) NOT NULL UNIQUE,
  password_hash VARCHAR(200) NOT NULL,
  display_name  VARCHAR(100) NOT NULL
);

-- Контент
CREATE TABLE content_items (
  content_id    BIGSERIAL PRIMARY KEY,
  title         VARCHAR(500) NOT NULL,
  content_type  content_type_enum NOT NULL,
  release_year  SMALLINT,
  language      VARCHAR(10),
  description   TEXT,
  creator       VARCHAR(200),     -- Автор/режиссёр/исполнитель 
  genres        JSONB,            -- Массив жанров, напр. ["Drama","Sci-Fi"]
  duration_min  INT CHECK (duration_min IS NULL OR duration_min >= 0),
  pages         INT CHECK (pages IS NULL OR pages >= 0)
);

CREATE INDEX idx_content_items_title ON content_items(title);

-- Коллекции пользователя
CREATE TABLE collections (
  collection_id BIGSERIAL PRIMARY KEY,
  user_id       BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  name          VARCHAR(100) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, name)
);

-- Связь M:N коллекции -- контент
CREATE TABLE collection_items (
  collection_id BIGINT NOT NULL REFERENCES collections(collection_id) ON DELETE CASCADE,
  content_id    BIGINT NOT NULL REFERENCES content_items(content_id)  ON DELETE CASCADE,
  PRIMARY KEY (collection_id, content_id)
);

CREATE INDEX idx_collection_items_content ON collection_items(content_id);

-- Списки пользователя
CREATE TABLE lists (
  list_id    BIGSERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  name       VARCHAR(100) NOT NULL,
  list_type  list_type_enum NOT NULL,
  UNIQUE (user_id, name)
);

-- Состав списков (M:N + порядок)
CREATE TABLE list_items (
  list_id    BIGINT NOT NULL REFERENCES lists(list_id)             ON DELETE CASCADE,
  content_id BIGINT NOT NULL REFERENCES content_items(content_id)  ON DELETE CASCADE,
  position   INT,
  PRIMARY KEY (list_id, content_id),
  UNIQUE (list_id, position)
);

CREATE INDEX idx_list_items_content ON list_items(content_id);

-- Оценки
CREATE TABLE ratings (
  user_id    BIGINT NOT NULL REFERENCES users(user_id)            ON DELETE CASCADE,
  content_id BIGINT NOT NULL REFERENCES content_items(content_id) ON DELETE CASCADE,
  score      SMALLINT NOT NULL CHECK (score BETWEEN 1 AND 10),
  review     TEXT,
  PRIMARY KEY (user_id, content_id)
);

CREATE INDEX idx_ratings_content ON ratings(content_id);


-- 2. НАПОЛНЕНИЕ БАЗЫ ДАННЫХ 

-- Пользователи
INSERT INTO users (email, password_hash, display_name) VALUES
  ('alice@example.com',   'hash_alice',   'Alice'),
  ('bob@example.com',     'hash_bob',     'Bob'),
  ('charlie@example.com', 'hash_charlie', 'Charlie');

-- Контент 
INSERT INTO content_items (
  title, content_type, release_year, language,
  description, creator, genres, duration_min, pages
) VALUES
  -- Книги
  ('The Hobbit', 'BOOK', 1937, 'en',
   'Fantasy novel about Bilbo Baggins.',
   'J.R.R. Tolkien',
   '["Fantasy","Adventure"]'::jsonb,
   NULL, 310),

  ('1984', 'BOOK', 1949, 'en',
   'Dystopian novel about totalitarian regime.',
   'George Orwell',
   '["Dystopia"]'::jsonb,
   NULL, 328),

  -- Фильмы
  ('Inception', 'MOVIE', 2010, 'en',
   'Dreams within dreams.',
   'Christopher Nolan',
   '["Sci-Fi","Thriller"]'::jsonb,
   148, NULL),

  ('Interstellar', 'MOVIE', 2014, 'en',
   'Space exploration through a wormhole.',
   'Christopher Nolan',
   '["Sci-Fi"]'::jsonb,
   169, NULL),

  -- Музыка
  ('Dark Side of the Moon', 'MUSIC', 1973, 'en',
   'Classic progressive rock.',
   'Pink Floyd',
   '["Rock"]'::jsonb,
   43, NULL),

  ('Bohemian Rhapsody', 'MUSIC', 1975, 'en',
   'Legendary rock song.',
   'Queen',
   '["Rock"]'::jsonb,
   6, NULL);

-- Коллекции 
INSERT INTO collections (user_id, name) VALUES
  (1, 'Favorites'),
  (2, 'Sci-Fi Collection'),
  (3, 'Rock Classics');

-- Элементы коллекций 
INSERT INTO collection_items (collection_id, content_id) VALUES
  (1, 1),  -- Hobbit
  (1, 3),  -- Inception
  (2, 2),  -- 1984
  (2, 4),  -- Interstellar
  (3, 5),  -- Dark Side of the Moon
  (3, 6),  -- Bohemian Rhapsody
  (1, 4);  -- Interstellar

-- Списки 
INSERT INTO lists (user_id, name, list_type) VALUES
  (1, 'Reading List',    'READING'),
  (2, 'Watchlist',       'WATCHING'),
  (3, 'Music Queue',     'LISTENING');

-- Элементы списков 
INSERT INTO list_items (list_id, content_id, position) VALUES
  (1, 1, 1), -- Hobbit
  (1, 2, 2), -- 1984
  (2, 3, 1), -- Inception
  (2, 4, 2), -- Interstellar
  (3, 5, 1), -- Dark Side
  (3, 6, 2); -- Bohemian

-- Оценки 
INSERT INTO ratings (user_id, content_id, score, review) VALUES
  (1, 1, 8, 'Great book.'),
  (1, 3, 9, 'Mind-blowing movie.'),
  (1, 5, 9, 'Classic album.'),

  (2, 2, 9, 'Strong and deep.'),
  (2, 4, 10, 'Amazing visuals.'),
  (2, 6, 8, 'Legendary song.'),

  (3, 5, 10, 'One of my favorites.'),
  (3, 3, 8, 'Good sci-fi.'),
  (3, 4, 9, 'Masterpiece.');


-- 3. ПРОСТЫЕ DML-ОПЕРАЦИИ

-- Добавить нового пользователя
INSERT INTO users (email, password_hash, display_name)
VALUES ('newuser@example.com', 'hash_new', 'New User');

-- Добавить новый список для существующего пользователя (Charlie, user_id = 3)
INSERT INTO lists (user_id, name, list_type)
VALUES (3, 'Charlie Watchlist', 'WATCHING');

-- Обновить отображаемое имя пользователя
UPDATE users
SET display_name = 'Alice Cooper'
WHERE user_id = 1;

-- Обновить оценку и отзыв по конкретному контенту
UPDATE ratings
SET score = 10,
    review = 'Masterpiece, must watch again.'
WHERE user_id = 2 AND content_id = 6;  -- Bohemian Rhapsody

-- Удалить список и его элементы (каскадно) — удаляем Music Queue пользователя 3
DELETE FROM lists
WHERE user_id = 3 AND name = 'Music Queue';

-- Удалить все оценки ниже 5 (низкие оценки)
DELETE FROM ratings
WHERE score < 5;


-- 4. ЗАПРОСЫ С АГРЕГАЦИЕЙ

-- Общее количество пользователей
SELECT COUNT(*) AS total_users
FROM users;

-- Количество контента по типу (книги, фильмы, музыка)
SELECT content_type, COUNT(*) AS items_count
FROM content_items
GROUP BY content_type;

-- Средний рейтинг и количество оценок по каждому контенту
SELECT
  ci.content_id,
  ci.title,
  AVG(r.score)   AS avg_score,
  COUNT(r.score) AS ratings_count
FROM content_items ci
LEFT JOIN ratings r ON ci.content_id = r.content_id
GROUP BY ci.content_id, ci.title;

-- Количество оценок у каждого пользователя
SELECT
  u.user_id,
  u.display_name,
  COUNT(r.content_id) AS ratings_count
FROM users u
LEFT JOIN ratings r ON u.user_id = r.user_id
GROUP BY u.user_id, u.display_name
ORDER BY ratings_count DESC;

-- Количество элементов в каждой коллекции
SELECT
  c.collection_id,
  c.name AS collection_name,
  u.display_name,
  COUNT(ci.content_id) AS items_count
FROM collections c
LEFT JOIN collection_items ci ON c.collection_id = ci.collection_id
JOIN users u ON c.user_id = u.user_id
GROUP BY c.collection_id, c.name, u.display_name;


-- 5. ЗАПРОСЫ С СОЕДИНЕНИЯМИ ТАБЛИЦ

-- Оценки пользователей с названиями контента
SELECT
  u.display_name,
  ci.title,
  r.score,
  r.review
FROM ratings r
JOIN users u ON r.user_id = u.user_id
JOIN content_items ci ON r.content_id = ci.content_id;

-- Элементы коллекций: пользователь, коллекция, контент
SELECT
  u.display_name,
  c.name AS collection_name,
  ci2.title AS content_title,
  ci2.content_type
FROM collections c
JOIN users u ON c.user_id = u.user_id
JOIN collection_items ci ON c.collection_id = ci.collection_id
JOIN content_items ci2 ON ci.content_id = ci2.content_id
ORDER BY u.display_name, c.name;

-- Элементы списков: пользователь, список, контент с порядком
SELECT
  u.display_name,
  l.name AS list_name,
  l.list_type,
  li.position,
  ci.title AS content_title
FROM list_items li
JOIN lists l ON li.list_id = l.list_id
JOIN users u ON l.user_id = u.user_id
JOIN content_items ci ON li.content_id = ci.content_id
ORDER BY u.display_name, l.name, li.position;


-- 6. СОЗДАНИЕ ПРЕДСТАВЛЕНИЙ

-- Средний рейтинг по каждому контенту
CREATE OR REPLACE VIEW content_avg_rating_view AS
SELECT
  ci.content_id,
  ci.title,
  ci.content_type,
  AVG(r.score)  AS avg_score,
  COUNT(r.score) AS ratings_count
FROM content_items ci
LEFT JOIN ratings r ON ci.content_id = r.content_id
GROUP BY ci.content_id, ci.title, ci.content_type;

-- Сводка по коллекциям пользователя
CREATE OR REPLACE VIEW user_collections_summary_view AS
SELECT
  u.user_id,
  u.display_name,
  COUNT(DISTINCT c.collection_id) AS collections_count,
  COUNT(ci.content_id)           AS total_items_in_collections
FROM users u
LEFT JOIN collections c ON u.user_id = c.user_id
LEFT JOIN collection_items ci ON c.collection_id = ci.collection_id
GROUP BY u.user_id, u.display_name;

-- Активность пользователя: рейтинги, списки, коллекции
CREATE OR REPLACE VIEW user_activity_view AS
SELECT
  u.user_id,
  u.display_name,
  COUNT(DISTINCT r.content_id) AS ratings_count,
  COUNT(DISTINCT l.list_id)    AS lists_count,
  COUNT(DISTINCT c.collection_id) AS collections_count
FROM users u
LEFT JOIN ratings r      ON u.user_id = r.user_id
LEFT JOIN lists l        ON u.user_id = l.user_id
LEFT JOIN collections c  ON u.user_id = c.user_id
GROUP BY u.user_id, u.display_name;
