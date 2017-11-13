-- Deploy mandatoaberto:0014-poll_name to pg
-- requires: 0013-politician_contact

BEGIN;

ALTER TABLE poll ADD COLUMN name TEXT;
UPDATE poll SET name = '';
ALTER TABLE poll ALTER COLUMN name SET NOT NULL;

COMMIT;
