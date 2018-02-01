-- Deploy mandatoaberto:0054-current-db-state to pg
-- requires: 0053-dm-groups-count

BEGIN;

ALTER TABLE issue ADD COLUMN reply TEXT;

ALTER TABLE issue DROP COLUMN status;
ALTER TABLE issue ADD COLUMN open BOOLEAN NOT NULL DEFAULT 'true';

ALTER TABLE recipient ADD COLUMN picture TEXT;

COMMIT;
