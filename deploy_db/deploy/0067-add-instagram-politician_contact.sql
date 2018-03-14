-- Deploy mandatoaberto:0067-add-instagram-politician_contact to pg
-- requires: 0066-user-confirmation

BEGIN;

ALTER TABLE politician_contact ADD COLUMN instagram TEXT;

COMMIT;
