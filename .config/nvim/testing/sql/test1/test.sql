CREATE TABLE tab0 (
    name_id INTEGER PRIMARY KEY NOT NULL,
    name VARCHAR(50)
);

CREATE TABLE tab1 (
    name_id INTEGER PRIMARY KEY NOT NULL,
    job VARCHAR(50)
);


INSERT INTO tab0 (name)
VALUES
    ('john'),
    ('jack'),
    ('joe')
;

INSERT INTO tab1 (job)
VALUES
    ('plummer'),
    ('doctor'),
    ('mechanic')
;

SELECT tab0.name, tab1.job
    FROM tab0
    INNER JOIN tab1
    ON tab0.name_id = tab1.name_id
;
