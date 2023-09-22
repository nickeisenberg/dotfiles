CREATE DATABASE test_db;

USE test_db;

CREATE TABLE table_1 (
    name_id INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name VARCHAR(50)
);

CREATE TABLE table_2 (
    name_id INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT,
    job VARCHAR(50)
);

INSERT INTO table_1 (
    name
) VALUES
    ('nick'),
    ('bill'),
    ('glen')
;

INSERT INTO table_2 (
    job
) VALUES
    ('programmer'),
    ('physicial'),
    ('plumber')
;
