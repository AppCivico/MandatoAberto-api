-- Deploy mandatoaberto:0057-recipient-picture to pg
-- requires: 0056-issue-open

BEGIN;

ALTER TABLE recipient ADD COLUMN picture TEXT;

COMMIT;
