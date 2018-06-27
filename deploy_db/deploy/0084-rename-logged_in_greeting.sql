-- Deploy mandatoaberto:0084-rename-logged_in_greeting to pg
-- requires: 0083-add-logged_in_greeting

BEGIN;

ALTER TABLE politician_votolegal_integration RENAME COLUMN logged_in_greeting TO greeting;

COMMIT;
