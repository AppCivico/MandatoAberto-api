-- Deploy mandatoaberto:0118-add-default-on-entities to pg
-- requires: 0117-add-custom_url

BEGIN;

ALTER TABLE recipient ALTER COLUMN entities SET DEFAULT '{}';
UPDATE recipient SET entities = '{}' WHERE entities = null;
ALTER TABLE recipient ALTER COLUMN entities SET NOT NULL;

COMMIT;
