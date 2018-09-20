-- Deploy mandatoaberto:0117-add-custom_url to pg
-- requires: 0116-add-available_types

BEGIN;

ALTER TABLE politician_votolegal_integration ADD COLUMN custom_url TEXT;

COMMIT;
