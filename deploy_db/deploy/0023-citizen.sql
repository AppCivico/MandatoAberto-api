-- Deploy mandatoaberto:0023-citizen to pg
-- requires: 0022-user_approved_bool

BEGIN;

CREATE TABLE citizen (
    id              SERIAL  PRIMARY KEY,
    politician_id   INTEGER NOT NULL REFERENCES politician(user_id),
    name            TEXT    NOT NULL,
    fb_id           TEXT    NOT NULL,
    origin_dialog   TEXT    NOT NULL,
    gender          TEXT
);

COMMIT;
