-- Deploy mandatoaberto:0119-set-notnull to pg
-- requires: 0118-add-default-on-entities

BEGIN;

UPDATE recipient SET entities = '{}'::int[] WHERE entities IS null;
ALTER TABLE recipient ALTER COLUMN entities SET NOT NULL;

COMMIT;
