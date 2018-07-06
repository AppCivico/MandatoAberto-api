-- Deploy mandatoaberto:0085-add-movement to pg
-- requires: 0084-rename-logged_in_greeting

BEGIN;

CREATE TABLE movement(
    id   SERIAL PRIMARY KEY,
    name TEXT   NOT NULL
);

INSERT INTO movement (name) VALUES
    ('Nós'),    ('Agora'),            ('RenovaBR'),
    ('Muitxs'), ('Bancada Ativista'), ('Acredito'),
    ('Participo de um movimento não listado');

ALTER TABLE politician ADD COLUMN movement_id INTEGER REFERENCES movement(id);

COMMIT;
