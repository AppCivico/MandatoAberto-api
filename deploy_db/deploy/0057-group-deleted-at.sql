-- Deploy mandatoaberto:0057-group-deleted-at to pg
-- requires: 0056-pollresult-citizen-to-recipient

BEGIN;

ALTER TABLE "group" ADD COLUMN deleted    BOOLEAN DEFAULT 'false';
ALTER TABLE "group" ADD COLUMN deleted_at TIMESTAMP WITHOUT TIME ZONE;

COMMIT;
