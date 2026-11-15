#!/bin/bash

set -e

echo "Создание базы данных..."
rm -f movies_rating.db
sqlite3 movies_rating.db < db_init.sql

echo "Задание 1. Рейтинг фильмов"
sqlite3 movies_rating.db <<'SQL'
WITH movie_avg AS (
    SELECT
        m.id,
        m.title,
        m.year,
        AVG(r.rating) AS avg_rating
    FROM movies AS m
    JOIN ratings AS r ON m.id = r.movie_id
    GROUP BY m.id, m.title, m.year
),
ranked_movies AS (
    SELECT
        title,
        year,
        avg_rating,
        RANK() OVER (ORDER BY avg_rating DESC) AS rank_by_avg_rating
    FROM movie_avg
)
SELECT
    title,
    year,
    ROUND(avg_rating, 2) AS avg_rating,
    rank_by_avg_rating
FROM ranked_movies
ORDER BY rank_by_avg_rating, title
LIMIT 10;
SQL

echo "Задание 2. Средняя оценка по жанрам"
sqlite3 movies_rating.db <<'SQL'
WITH RECURSIVE split_genres(movie_id, genre, rest) AS (
    SELECT id, '', genres || '|' FROM movies
    UNION ALL
    SELECT
        movie_id,
        substr(rest, 1, instr(rest, '|') - 1),
        substr(rest, instr(rest, '|') + 1)
    FROM split_genres
    WHERE rest <> ''
),
genre_ratings AS (
    SELECT
        genre,
        AVG(r.rating) AS avg_rating
    FROM split_genres AS sg
    JOIN ratings AS r ON sg.movie_id = r.movie_id
    WHERE genre <> ''
    GROUP BY genre
)
SELECT
    genre,
    ROUND(avg_rating, 2) AS avg_rating,
    RANK() OVER (ORDER BY avg_rating DESC) AS rank_by_avg_rating
FROM genre_ratings
ORDER BY rank_by_avg_rating, genre;
SQL

echo "Задание 3. Количество фильмов по жанрам"
sqlite3 movies_rating.db <<'SQL'
WITH RECURSIVE split_genres(movie_id, genre, rest) AS (
    SELECT id, '', genres || '|' FROM movies
    UNION ALL
    SELECT
        movie_id,
        substr(rest, 1, instr(rest, '|') - 1),
        substr(rest, instr(rest, '|') + 1)
    FROM split_genres
    WHERE rest <> ''
)
SELECT
    genre,
    COUNT(DISTINCT movie_id) AS movie_count
FROM split_genres
WHERE genre <> ''
GROUP BY genre
ORDER BY movie_count DESC, genre;
SQL

echo "Задание 4. Количество тегов по жанрам"
sqlite3 movies_rating.db <<'SQL'
WITH RECURSIVE split_genres(movie_id, genre, rest) AS (
    SELECT id, '', genres || '|' FROM movies
    UNION ALL
    SELECT
        movie_id,
        substr(rest, 1, instr(rest, '|') - 1),
        substr(rest, instr(rest, '|') + 1)
    FROM split_genres
    WHERE rest <> ''
),
genre_tags AS (
    SELECT
        sg.genre,
        COUNT(t.id) AS tag_count
    FROM split_genres AS sg
    JOIN tags AS t ON sg.movie_id = t.movie_id
    WHERE sg.genre <> ''
    GROUP BY sg.genre
)
SELECT
    genre,
    tag_count,
    ROUND(
        tag_count * 100.0 / (SELECT COUNT(*) FROM tags),
        2
    ) AS tag_share
FROM genre_tags
ORDER BY tag_count DESC, genre;
SQL

echo "Задание 5. Статистика оценок пользователей"
sqlite3 movies_rating.db <<'SQL'
SELECT
    u.id AS user_id,
    COUNT(r.id) AS rating_count,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    MIN(date(r.timestamp, 'unixepoch')) AS first_rating_date,
    MAX(date(r.timestamp, 'unixepoch')) AS last_rating_date
FROM users AS u
LEFT JOIN ratings AS r ON u.id = r.user_id
GROUP BY u.id
ORDER BY rating_count DESC, user_id
LIMIT 10;
SQL

echo "Задание 6. Сегментация пользователей"
sqlite3 movies_rating.db <<'SQL'
WITH user_activity AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT r.id) AS rating_count,
        COUNT(DISTINCT t.id) AS tag_count
    FROM users AS u
    LEFT JOIN ratings AS r ON u.id = r.user_id
    LEFT JOIN tags AS t ON u.id = t.user_id
    GROUP BY u.id
)
SELECT
    user_id,
    rating_count,
    tag_count,
    CASE
        WHEN rating_count >= 10 AND tag_count >= 10
            THEN 'Активные'
        WHEN rating_count < 5 AND tag_count < 5
            THEN 'Пассивные'
        WHEN tag_count > rating_count
            THEN 'Комментаторы'
        WHEN rating_count > tag_count
            THEN 'Оценщики'
        ELSE 'Не классифицированы'
    END AS user_segment
FROM user_activity
ORDER BY user_id;
SQL

echo "Задание 7. Последний оценённый фильм каждого пользователя"
sqlite3 movies_rating.db <<'SQL'
WITH ranked_ratings AS (
    SELECT
        user_id,
        movie_id,
        timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY timestamp DESC, id DESC
        ) AS rn
    FROM ratings
)
SELECT
    u.id AS user_id,
    u.name,
    m.title AS last_movie,
    date(rr.timestamp, 'unixepoch') AS last_rating_date
FROM users AS u
LEFT JOIN ranked_ratings AS rr
    ON u.id = rr.user_id AND rr.rn = 1
LEFT JOIN movies AS m
    ON rr.movie_id = m.id
ORDER BY u.id;
SQL

echo "Все семь заданий выполнены!"
