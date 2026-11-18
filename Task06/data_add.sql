-- Lab 6: insert five students, three movies with different genres,
-- and three ratings by Serov Stanislav Aleksandrovich.
-- Run after db_init.sql. Emails are fictional placeholders, not actual contacts.
-- Uses lookups instead of hard-coded existing IDs.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- The gender and occupation entries below are editable example values;
-- confirm them with the participants before using real personal data.
INSERT INTO users (first_name, last_name, email, gender, occupation_id)
SELECT 'Владислав Сергеевич', 'Романов', 'lab06.romanov@example.com', 'male', o.id
FROM occupations AS o WHERE o.name = 'student'
  AND NOT EXISTS (SELECT 1 FROM users WHERE email = 'lab06.romanov@example.com');

INSERT INTO users (first_name, last_name, email, gender, occupation_id)
SELECT 'Роман Андреевич', 'Салагаев', 'lab06.salagaev@example.com', 'male', o.id
FROM occupations AS o WHERE o.name = 'student'
  AND NOT EXISTS (SELECT 1 FROM users WHERE email = 'lab06.salagaev@example.com');

INSERT INTO users (first_name, last_name, email, gender, occupation_id)
SELECT 'Станислав Александрович', 'Серов', 'lab06.serov@example.com', 'male', o.id
FROM occupations AS o WHERE o.name = 'student'
  AND NOT EXISTS (SELECT 1 FROM users WHERE email = 'lab06.serov@example.com');

INSERT INTO users (first_name, last_name, email, gender, occupation_id)
SELECT 'Александр Сергеевич', 'Смирнов', 'lab06.smirnov@example.com', 'male', o.id
FROM occupations AS o WHERE o.name = 'student'
  AND NOT EXISTS (SELECT 1 FROM users WHERE email = 'lab06.smirnov@example.com');

INSERT INTO users (first_name, last_name, email, gender, occupation_id)
SELECT 'Арслан Риянович', 'Умяров', 'lab06.umyarov@example.com', 'male', o.id
FROM occupations AS o WHERE o.name = 'student'
  AND NOT EXISTS (SELECT 1 FROM users WHERE email = 'lab06.umyarov@example.com');

-- Three real films, each linked to a different genre.
INSERT INTO movies (title, year)
SELECT 'Inside Out 2', 2024
WHERE NOT EXISTS (SELECT 1 FROM movies WHERE title = 'Inside Out 2' AND year = 2024);

INSERT INTO movies (title, year)
SELECT 'The Brutalist', 2024
WHERE NOT EXISTS (SELECT 1 FROM movies WHERE title = 'The Brutalist' AND year = 2024);

INSERT INTO movies (title, year)
SELECT 'Dune: Part Two', 2024
WHERE NOT EXISTS (SELECT 1 FROM movies WHERE title = 'Dune: Part Two' AND year = 2024);

-- Use genre names and movie titles to find keys dynamically.
INSERT OR IGNORE INTO movie_genres(movie_id, genre_id)
SELECT m.id, g.id FROM movies m CROSS JOIN genres g
WHERE m.title = 'Inside Out 2' AND m.year = 2024 AND g.name = 'Comedy';

INSERT OR IGNORE INTO movie_genres(movie_id, genre_id)
SELECT m.id, g.id FROM movies m CROSS JOIN genres g
WHERE m.title = 'The Brutalist' AND m.year = 2024 AND g.name = 'Drama';

INSERT OR IGNORE INTO movie_genres(movie_id, genre_id)
SELECT m.id, g.id FROM movies m CROSS JOIN genres g
WHERE m.title = 'Dune: Part Two' AND m.year = 2024 AND g.name = 'Sci-Fi';

-- Ratings: user_id and movie_id are obtained via SELECT, not fixed numbers.
-- No rating duplicates if the script is run more than once.
INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.id, 4.5 FROM users u CROSS JOIN movies m
WHERE u.email = 'lab06.serov@example.com'
  AND m.title = 'Inside Out 2' AND m.year = 2024
  AND NOT EXISTS (SELECT 1 FROM ratings r WHERE r.user_id = u.id AND r.movie_id = m.id);

INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.id, 5.0 FROM users u CROSS JOIN movies m
WHERE u.email = 'lab06.serov@example.com'
  AND m.title = 'The Brutalist' AND m.year = 2024
  AND NOT EXISTS (SELECT 1 FROM ratings r WHERE r.user_id = u.id AND r.movie_id = m.id);

INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.id, 4.0 FROM users u CROSS JOIN movies m
WHERE u.email = 'lab06.serov@example.com'
  AND m.title = 'Dune: Part Two' AND m.year = 2024
  AND NOT EXISTS (SELECT 1 FROM ratings r WHERE r.user_id = u.id AND r.movie_id = m.id);

COMMIT;
