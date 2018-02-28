-- Deploy mandatoaberto:0056-pollresult-citizen-to-recipient to pg
-- requires: 0055-current-db-state

BEGIN;

ALTER TABLE poll_result RENAME COLUMN citizen_id TO recipient_id;

COMMIT;
