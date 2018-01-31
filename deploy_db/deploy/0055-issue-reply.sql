-- Deploy mandatoaberto:0055-issue-reply to pg
-- requires: 0054-issue-table

BEGIN;

ALTER TABLE issue ADD COLUMN reply TEXT;

COMMIT;
