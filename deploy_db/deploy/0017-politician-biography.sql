-- Deploy mandatoaberto:0017-politician-biography to pg
-- requires: 0016-poll-active-boolean

BEGIN;

CREATE TABLE politician_biography (
    id              SERIAL  PRIMARY KEY,
    politician_id   INTEGER NOT NULL REFERENCES politician(user_id),
    content         TEXT    NOT NULL
);

COMMIT;
