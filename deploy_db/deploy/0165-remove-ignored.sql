-- Deploy mandatoaberto:0165-remove-ignored to pg
-- requires: 0164-update-sub_module-human_name

BEGIN;

ALTER TABLE issue DROP column open, DROP COLUMN ignored;


COMMIT;
