-- 1. ПРОЦЕДУРЫ И ФУНКЦИИ
-- 1.1. Безопасное добавление/обновление оценки (rating) с обработкой ошибок

CREATE OR REPLACE FUNCTION add_rating_safe(
    p_user_id    BIGINT,
    p_content_id BIGINT,
    p_score      SMALLINT,
    p_review     TEXT DEFAULT NULL
) RETURNS TEXT AS $$
BEGIN
    -- Бизнес-проверка диапазона оценки
    IF p_score < 1 OR p_score > 10 THEN
        RETURN 'Бизнес-ошибка: оценка должна быть от 1 до 10';
    END IF;

    -- Проверка существования пользователя
    IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_user_id) THEN
        RETURN 'Бизнес-ошибка: пользователь с таким id не найден';
    END IF;

    -- Проверка существования контента
    IF NOT EXISTS (SELECT 1 FROM content_items WHERE content_id = p_content_id) THEN
        RETURN 'Бизнес-ошибка: контент с таким id не найден';
    END IF;

    -- Если оценка уже есть — обновляем, иначе вставляем новую
    IF EXISTS (
        SELECT 1
        FROM ratings
        WHERE user_id = p_user_id AND content_id = p_content_id
    ) THEN
        UPDATE ratings
        SET score  = p_score,
            review = COALESCE(p_review, review)
        WHERE user_id = p_user_id AND content_id = p_content_id;

        RETURN 'Оценка обновлена для user_id = ' || p_user_id ||
               ', content_id = ' || p_content_id;
    ELSE
        INSERT INTO ratings(user_id, content_id, score, review)
        VALUES (p_user_id, p_content_id, p_score, p_review);

        RETURN 'Оценка добавлена для user_id = ' || p_user_id ||
               ', content_id = ' || p_content_id;
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RETURN 'Бизнес-ошибка: нарушена ссылка внешнего ключа (user_id или content_id некорректен)';
    WHEN unique_violation THEN
        RETURN 'Бизнес-ошибка: дубликат оценки (user_id + content_id уже существует)';
    WHEN OTHERS THEN
        RETURN 'Неизвестная ошибка при добавлении/обновлении оценки: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;


-- 1.2. Добавление элемента в список с автоматической позицией

CREATE OR REPLACE FUNCTION add_list_item_safe(
    p_list_id    BIGINT,
    p_content_id BIGINT
) RETURNS TEXT AS $$
DECLARE
    v_next_position INT;
BEGIN
    -- Проверка существования списка
    IF NOT EXISTS (SELECT 1 FROM lists WHERE list_id = p_list_id) THEN
        RETURN 'Бизнес-ошибка: список с таким id не найден';
    END IF;

    -- Проверка существования контента
    IF NOT EXISTS (SELECT 1 FROM content_items WHERE content_id = p_content_id) THEN
        RETURN 'Бизнес-ошибка: контент с таким id не найден';
    END IF;

    -- Проверка, нет ли уже такого контента в списке
    IF EXISTS (
        SELECT 1
        FROM list_items
        WHERE list_id = p_list_id AND content_id = p_content_id
    ) THEN
        RETURN 'Бизнес-ошибка: этот контент уже есть в списке';
    END IF;

    -- Определяем следующую позицию (max + 1)
    SELECT COALESCE(MAX(position) + 1, 1)
    INTO v_next_position
    FROM list_items
    WHERE list_id = p_list_id;

    INSERT INTO list_items(list_id, content_id, position)
    VALUES (p_list_id, p_content_id, v_next_position);

    RETURN 'Элемент добавлен в список ' || p_list_id ||
           ' на позицию ' || v_next_position;

EXCEPTION
    WHEN unique_violation THEN
        RETURN 'Бизнес-ошибка: конфликт уникальности (позиция или пара list_id+content_id уже занята)';
    WHEN foreign_key_violation THEN
        RETURN 'Бизнес-ошибка: некорректные ссылки (list_id или content_id)';
    WHEN OTHERS THEN
        RETURN 'Неизвестная ошибка при добавлении элемента в список: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;


-- 1.3. Статистика по пользователю: количество коллекций, списков, оценок и средняя оценка

CREATE OR REPLACE FUNCTION get_user_library_stats(p_user_id BIGINT)
RETURNS TABLE(
    collections_count INTEGER,
    lists_count       INTEGER,
    ratings_count     INTEGER,
    avg_user_score    NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM collections c WHERE c.user_id = p_user_id),
        (SELECT COUNT(*) FROM lists      l WHERE l.user_id = p_user_id),
        (SELECT COUNT(*) FROM ratings    r WHERE r.user_id = p_user_id),
        (SELECT AVG(r.score)::NUMERIC    FROM ratings r WHERE r.user_id = p_user_id);
END;
$$ LANGUAGE plpgsql;


-- 2. ТРИГГЕРЫ И ДОПОЛНИТЕЛЬНЫЕ СТРУКТУРЫ

-- 2.1. Триггер проверки бизнес-правил для ratings (диапазон оценки)

CREATE OR REPLACE FUNCTION trg_ratings_check_score()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.score < 1 OR NEW.score > 10 THEN
        RAISE EXCEPTION
            'Некорректная оценка: % (допустимо от 1 до 10)', NEW.score
            USING ERRCODE = 'P0001',
                  MESSAGE  = 'Бизнес-ошибка: оценка должна быть от 1 до 10';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ratings_check_score ON ratings;

CREATE TRIGGER ratings_check_score
BEFORE INSERT OR UPDATE ON ratings
FOR EACH ROW EXECUTE FUNCTION trg_ratings_check_score();


-- 2.2. Счетчик оценок по контенту (rating_count в content_items)

ALTER TABLE content_items
    ADD COLUMN IF NOT EXISTS rating_count INTEGER NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION trg_content_items_rating_counter()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE content_items
        SET rating_count = rating_count + 1
        WHERE content_id = NEW.content_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE content_items
        SET rating_count = rating_count - 1
        WHERE content_id = OLD.content_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS content_items_rating_counter ON ratings;

CREATE TRIGGER content_items_rating_counter
AFTER INSERT OR DELETE ON ratings
FOR EACH ROW EXECUTE FUNCTION trg_content_items_rating_counter();


-- 2.3. Аудит изменений оценок (INSERT/UPDATE/DELETE в отдельную таблицу)

CREATE TABLE IF NOT EXISTS rating_audit (
    audit_id     BIGSERIAL PRIMARY KEY,
    user_id      BIGINT,
    content_id   BIGINT,
    old_score    SMALLINT,
    new_score    SMALLINT,
    action_type  VARCHAR(10),  -- INSERT / UPDATE / DELETE
    action_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION trg_ratings_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO rating_audit(user_id, content_id, old_score, new_score, action_type)
        VALUES (NEW.user_id, NEW.content_id, NULL, NEW.score, 'INSERT');
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO rating_audit(user_id, content_id, old_score, new_score, action_type)
        VALUES (NEW.user_id, NEW.content_id, OLD.score, NEW.score, 'UPDATE');
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO rating_audit(user_id, content_id, old_score, new_score, action_type)
        VALUES (OLD.user_id, OLD.content_id, OLD.score, NULL, 'DELETE');
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ratings_audit ON ratings;

CREATE TRIGGER ratings_audit
AFTER INSERT OR UPDATE OR DELETE ON ratings
FOR EACH ROW EXECUTE FUNCTION trg_ratings_audit();


-- 3. ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ
-- 3.1. Проверка функций (бизнес-логика и обработка ошибок)

-- Успешное добавление новой оценки
SELECT add_rating_safe(1, 2, 7, 'Интересная книга');  -- user 1, content 2 (1984)

-- Обновление существующей оценки
SELECT add_rating_safe(1, 1, 9, 'Очень понравилось, перечитаю');  -- Hobbit

-- Попытка выставить некорректную оценку (триггер + бизнес-сообщение от функции)
SELECT add_rating_safe(1, 3, 15, 'Слишком высокая оценка');  -- должно вернуть бизнес-ошибку

-- Добавление элемента в существующий список (у нас есть list_id = 1..3)
-- Добавим Hobbit (1) в Watchlist пользователя 2 (list_id = 2)
SELECT add_list_item_safe(2, 1);

-- Попытка добавить тот же контент в тот же список второй раз (получим бизнес-сообщение)
SELECT add_list_item_safe(2, 1);

-- Статистика по пользователю (например, user_id = 1)
SELECT * FROM get_user_library_stats(1);


-- 3.2. Проверка триггеров

-- До вставки
SELECT content_id, title, rating_count
FROM content_items
ORDER BY content_id;

-- Вставляем новую оценку (rating_count для этого content_id должен увеличиться)
INSERT INTO ratings(user_id, content_id, score, review)
VALUES (2, 1, 6, 'Неплохо, но могло быть лучше');

-- После вставки
SELECT content_id, title, rating_count
FROM content_items
ORDER BY content_id;

-- Удаляем только что вставленную оценку
DELETE FROM ratings
WHERE user_id = 2 AND content_id = 1 AND score = 6;

-- После удаления
SELECT content_id, title, rating_count
FROM content_items
ORDER BY content_id;

-- Вставка новой оценки
INSERT INTO ratings(user_id, content_id, score, review)
VALUES (3, 2, 8, 'Хорошая антиутопия');

-- Обновление этой оценки
UPDATE ratings
SET score = 9
WHERE user_id = 3 AND content_id = 2;

-- Удаление оценки
DELETE FROM ratings
WHERE user_id = 3 AND content_id = 2;

-- Просмотр лога аудита
SELECT *
FROM rating_audit
ORDER BY action_at DESC, audit_id DESC; 