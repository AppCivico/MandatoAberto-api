-- Deploy mandatoaberto:0154-poll_propagate to pg
-- requires: 0153-fix-duplicate-intents

BEGIN;

ALTER TABLE poll_propagate DROP COLUMN politician_id, DROP COLUMN count;

COMMIT;
