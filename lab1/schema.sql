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
