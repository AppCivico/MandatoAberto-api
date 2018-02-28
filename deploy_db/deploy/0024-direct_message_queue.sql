-- Deploy mandatoaberto:0024-direct_message_queue to pg
-- requires: 0023-citizen

BEGIN;

CREATE TABLE direct_message_queue (
    id              SERIAL PRIMARY KEY,
    content         TEXT   NOT NULL,
    created_at      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
