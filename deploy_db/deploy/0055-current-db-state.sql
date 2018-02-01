-- Deploy mandatoaberto:0055-current-db-state to pg
-- requires: 0054-issue-table

BEGIN;

ALTER TABLE issue ADD COLUMN reply TEXT;

ALTER TABLE issue DROP COLUMN status;
ALTER TABLE issue ADD COLUMN open BOOLEAN NOT NULL DEFAULT 'true';

ALTER TABLE recipient ADD COLUMN picture TEXT;

COMMIT;
