-- Deploy mandatoaberto:0120-add-deleted-boolean to pg
-- requires: 0119-set-notnull

BEGIN;

ALTER TABLE issue ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT false;

COMMIT;
