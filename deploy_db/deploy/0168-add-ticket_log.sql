-- Deploy mandatoaberto:0168-add-ticket_log to pg
-- requires: 0167-add-ticket

BEGIN;

CREATE TABLE ticket_log (
    ticket_id  INTEGER NOT NULL REFERENCES ticket(id),
    text       TEXT    NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
