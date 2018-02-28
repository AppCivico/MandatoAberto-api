-- Deploy mandatoaberto:0006-question to pg
-- requires: 0005-dialog

BEGIN;

CREATE TABLE question (
    id          SERIAL  PRIMARY KEY,
    dialog_id   INTEGER NOT NULL REFERENCES dialog(id),
    name        TEXT    NOT NULL
);

COMMIT;
