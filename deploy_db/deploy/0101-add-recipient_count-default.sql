-- Deploy mandatoaberto:0101-add-recipient_count-default to pg
-- requires: 0100-add-dm-columns

BEGIN;

ALTER TABLE politician_entity ALTER COLUMN recipient_count SET DEFAULT 0;

COMMIT;
