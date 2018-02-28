-- Deploy mandatoaberto:0049-add-tag to pg
-- requires: 0048-relations-names

BEGIN;

CREATE TABLE tag (
    id            SERIAL PRIMARY KEY,
    politician_id INTEGER NOT NULL REFERENCES politician(user_id),
    name          TEXT NOT NULL,
    filter        JSON NOT NULL,
    calc          BOOLEAN NOT NULL DEFAULT 'false',
    last_calc_at  TIMESTAMP WITHOUT TIME ZONE,
    created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP WITHOUT TIME ZONE
);

COMMIT;
