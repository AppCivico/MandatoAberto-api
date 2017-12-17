-- Deploy mandatoaberto:0036-dm-created_at to pg
-- requires: 0035-poll-timestamps

BEGIN;

ALTER TABLE direct_message DROP COLUMN sent_at;
ALTER TABLE direct_message ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW();
UPDATE direct_message SET created_at = now();
ALTER TABLE direct_message ALTER COLUMN created_at SET NOT NULL;

COMMIT;
