-- Deploy mandatoaberto:0025-direct-message-table to pg
-- requires: 0024-direct_message_queue

BEGIN;

CREATE TABLE direct_message (
    id             SERIAL  PRIMARY KEY,
    politician_id  INTEGER NOT NULL REFERENCES politician(user_id),
    content        TEXT    NOT NULL,
    sent           BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at        TIMESTAMP WITHOUT TIME ZONE
);

ALTER TABLE direct_message_queue DROP COLUMN content;
ALTER TABLE direct_message_queue ADD COLUMN politician_id INTEGER NOT NULL REFERENCES politician(user_id), ADD COLUMN direct_message_id INTEGER NOT NULL REFERENCES direct_message(id);

COMMIT;
