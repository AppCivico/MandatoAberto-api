-- Deploy mandatoaberto:0075-setting-created_by_admin_id-notnull to pg
-- requires: 0074-adding-admin-timestamps-and-ids

BEGIN;

ALTER TABLE question ALTER COLUMN created_by_admin_id SET NOT NULL;
ALTER TABLE dialog ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE question ALTER COLUMN updated_at DROP DEFAULT;

COMMIT;
