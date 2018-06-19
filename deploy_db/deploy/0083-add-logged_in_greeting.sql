-- Deploy mandatoaberto:0083-add-logged_in_greeting to pg
-- requires: 0082-politician_private_reply_config

BEGIN;

ALTER TABLE politician_votolegal_integration ADD COLUMN logged_in_greeting TEXT;

COMMIT;
