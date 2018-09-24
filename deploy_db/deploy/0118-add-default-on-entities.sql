-- Deploy mandatoaberto:0118-add-default-on-entities to pg
-- requires: 0117-add-custom_url

BEGIN;

ALTER TABLE recipient ALTER COLUMN entities SET DEFAULT '{}'::int[];
UPDATE recipient SET entities = '{}'::int[] WHERE entities = null;
ALTER TABLE recipient ALTER COLUMN entities SET NOT NULL;

COMMIT;
