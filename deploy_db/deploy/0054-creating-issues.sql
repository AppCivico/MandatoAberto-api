-- Deploy mandatoaberto:0054-creating-issues to pg
-- requires: 0053-dm-groups-count

BEGIN;

CREATE TABLE issue (
    id            SERIAL PRIMARY KEY,
    politician_id INTEGER REFERENCES politician(user_id) NOT NULL,
    recipient_id  INTEGER REFERENCES recipient(id) NOT NULL,
    message       TEXT NOT NULL,
    status        TEXT NOT NULL,
    updated_at    TIMESTAMP WITHOUT TIME ZONE,
    created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;