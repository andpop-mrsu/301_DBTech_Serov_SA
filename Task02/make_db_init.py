#!/usr/bin/env python3
"""Генерирует db_init.sql: создание таблиц и загрузка данных в Movies_rating.db."""
import csv
import os
import re

BASE = os.path.dirname(os.path.abspath(__file__))  # папка скрипта, работает на любой ОС


def q(value):
    
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def write_inserts(out, table, columns, rows, batch=500):
    
    cols = ", ".join(columns)
    for i in range(0, len(rows), batch):
        chunk = rows[i:i + batch]
        values = ",\n".join("(" + ", ".join(q(v) for v in r) + ")" for r in chunk)
        out.write(f"INSERT INTO {table} ({cols}) VALUES\n{values};\n")


def read_movies():
    rows = []
    with open(os.path.join(BASE, "movies.csv"), encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            title = r["title"].strip()
            m = re.search(r"\((\d{4})\)\s*$", title)  # год в конце названия
            year = int(m.group(1)) if m else None
            if m:
                title = title[:m.start()].strip()
            rows.append((int(r["movieId"]), title, year, r["genres"]))
    return rows


def read_ratings():
    rows = []
    with open(os.path.join(BASE, "ratings.csv"), encoding="utf-8", newline="") as f:
        for n, r in enumerate(csv.DictReader(f), start=1):
            rows.append((n, int(r["userId"]), int(r["movieId"]),
                         float(r["rating"]), int(r["timestamp"])))
    return rows


def read_tags():
    rows = []
    with open(os.path.join(BASE, "tags.csv"), encoding="utf-8", newline="") as f:
        for n, r in enumerate(csv.DictReader(f), start=1):
            rows.append((n, int(r["userId"]), int(r["movieId"]),
                         r["tag"], int(r["timestamp"])))
    return rows


def read_users():
    rows = []
    with open(os.path.join(BASE, "users.txt"), encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            uid, name, email, gender, reg_date, occupation = line.split("|")
            rows.append((int(uid), name, email, gender, reg_date, occupation))
    return rows


SCHEMA = """
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS users;

CREATE TABLE movies (
    id     INTEGER PRIMARY KEY,
    title  VARCHAR(160) NOT NULL,
    year   INTEGER,
    genres VARCHAR(80)
);

CREATE TABLE ratings (
    id        INTEGER PRIMARY KEY,
    user_id   INTEGER NOT NULL,
    movie_id  INTEGER NOT NULL,
    rating    REAL NOT NULL,
    timestamp INTEGER NOT NULL
);

CREATE TABLE tags (
    id        INTEGER PRIMARY KEY,
    user_id   INTEGER NOT NULL,
    movie_id  INTEGER NOT NULL,
    tag       VARCHAR(90) NOT NULL,
    timestamp INTEGER NOT NULL
);

CREATE TABLE users (
    id            INTEGER PRIMARY KEY,
    name          VARCHAR(40) NOT NULL,
    email         VARCHAR(40) NOT NULL,
    gender        VARCHAR(10) NOT NULL,
    register_date TEXT NOT NULL,
    occupation    VARCHAR(20) NOT NULL
);
"""


def main():
    with open(os.path.join(BASE, "db_init.sql"), "w", encoding="utf-8", newline="\n") as out:
        out.write(SCHEMA.lstrip("\n") + "\nBEGIN TRANSACTION;\n")
        write_inserts(out, "movies", ["id", "title", "year", "genres"], read_movies())
        write_inserts(out, "ratings", ["id", "user_id", "movie_id", "rating", "timestamp"], read_ratings())
        write_inserts(out, "tags", ["id", "user_id", "movie_id", "tag", "timestamp"], read_tags())
        write_inserts(out, "users", ["id", "name", "email", "gender", "register_date", "occupation"], read_users())
        out.write("COMMIT;\n")


if __name__ == "__main__":
    main()
