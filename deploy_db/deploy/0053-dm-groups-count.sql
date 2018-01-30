-- Deploy mandatoaberto:0053-dm-groups-count to pg
-- requires: 0052-rename-tags-groups

BEGIN;

ALTER TABLE direct_message ADD COLUMN groups INTEGER [], ADD COLUMN count INTEGER;
UPDATE direct_message SET count = 0;
ALTER TABLE direct_message ALTER COLUMN count SET NOT NULL;

COMMIT;
