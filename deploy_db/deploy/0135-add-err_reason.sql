-- Deploy mandatoaberto:0135-add-err_reason to pg
-- requires: 0134-remove-type

BEGIN;

ALTER TABLE campaign ADD COLUMN err_reason TEXT;

COMMIT;
