-- Deploy mandatoaberto:0022-user_approved_bool to pg
-- requires: 0021-drop-politician-biography

BEGIN;

ALTER TABLE politician DROP COLUMN approved, DROP COLUMN approved_at;
ALTER TABLE "user" ADD COLUMN approved BOOLEAN DEFAULT FALSE, ADD COLUMN approved_at TIMESTAMP WITHOUT TIME ZONE;
ALTER TABLE "user" ALTER COLUMN approved SET NOT NULL;

COMMIT;
