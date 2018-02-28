-- Deploy mandatoaberto:0041-poll-updated_at to pg
-- requires: 0040-greetings-update

BEGIN;

ALTER TABLE poll ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE;

COMMIT;
