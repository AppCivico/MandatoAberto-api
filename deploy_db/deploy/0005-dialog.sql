-- Deploy mandatoaberto:0005-dialog to pg
-- requires: 0004-forgot-password

BEGIN;

CREATE TABLE dialog (
    id   SERIAL PRIMARY KEY,
    name TEXT   NOT NULL
);

COMMIT;
