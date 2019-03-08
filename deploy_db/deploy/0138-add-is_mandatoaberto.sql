-- Deploy mandatoaberto:0138-add-is_mandatoaberto to pg
-- requires: 0137-add-organization

BEGIN;

ALTER TABLE organization ADD COLUMN is_mandatoaberto BOOLEAN DEFAULT true NOT NULL;

COMMIT;
