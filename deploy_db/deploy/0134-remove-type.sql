-- Deploy mandatoaberto:0134-remove-type to pg
-- requires: 0133-add-politician_entity_stats

BEGIN;

ALTER TABLE direct_message DROP COLUMN type;

COMMIT;
