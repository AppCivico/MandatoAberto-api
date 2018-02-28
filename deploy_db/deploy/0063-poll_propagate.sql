-- Deploy mandatoaberto:0063-poll_propagate to pg
-- requires: 0062-private_reply-permalink

BEGIN;

CREATE TABLE poll_propagate (
    id         SERIAL PRIMARY KEY,
    poll_id    INTEGER REFERENCES poll(id) NOT NULL,
    groups     INTEGER [],
    count      INTEGER NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE poll_result ADD COLUMN origin TEXT;
UPDATE poll_result SET origin = 'dialog';
ALTER TABLE poll_result ALTER COLUMN origin SET NOT NULL;

COMMIT;
