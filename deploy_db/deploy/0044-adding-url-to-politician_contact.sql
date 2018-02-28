-- Deploy mandatoaberto:0044-adding-url-to-politician_contact to pg
-- requires: 0043-updating-party

BEGIN;

ALTER TABLE politician_contact ADD COLUMN url TEXT;

COMMIT;
