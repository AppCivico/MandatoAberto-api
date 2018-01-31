-- Deploy mandatoaberto:0056-issue-open to pg
-- requires: 0055-issue-reply

BEGIN;

ALTER TABLE issue DROP COLUMN status;
ALTER TABLE issue ADD COLUMN open BOOLEAN NOT NULL DEFAULT 'true';

COMMIT;
