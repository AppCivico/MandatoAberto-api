-- Deploy mandatoaberto:0013-politician_contact to pg
-- requires: 0012-polls-questions-and-options

BEGIN;

CREATE TABLE politician_contact (
    id            SERIAL PRIMARY KEY,
    politician_id INTEGER NOT NULL REFERENCES politician(user_id),
    twitter       TEXT,
    facebook      TEXT,
    email         TEXT,
    cellphone     TEXT 
);

COMMIT;
