-- Deploy mandatoaberto:0047-rename-citizen-to-recipient to pg
-- requires: 0046-politician-premium

BEGIN;

ALTER TABLE citizen RENAME to recipient;

COMMIT;
