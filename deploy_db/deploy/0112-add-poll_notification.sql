-- Deploy mandatoaberto:0112-add-poll_notification to pg
-- requires: 0111-updating-picframe

BEGIN;

CREATE TABLE poll_notification (
    id           SERIAL  PRIMARY KEY,
    poll_id      INTEGER NOT NULL REFERENCES poll(id),
    recipient_id INTEGER NOT NULL REFERENCES recipient(id) UNIQUE,
    sent         BOOLEAN NOT NULL DEFAULT false,
    updated_at   TIMESTAMP WITHOUT TIME ZONE
);

COMMIT;
