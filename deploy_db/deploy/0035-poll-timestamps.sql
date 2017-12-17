-- Deploy mandatoaberto:0035-poll-timestamps to pg
-- requires: 0034-poll-results

BEGIN;

ALTER TABLE poll 
    ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    ADD COLUMN activated_at TIMESTAMP WITHOUT TIME ZONE;

UPDATE poll SET created_at = now();
ALTER TABLE poll ALTER COLUMN created_at SET NOT NULL;

COMMIT;
