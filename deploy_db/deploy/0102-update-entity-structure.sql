-- Deploy mandatoaberto:0102-update-entity-structure to pg
-- requires: 0101-add-recipient_count-default

BEGIN;

DELETE FROM politician_entity WHERE entity_id IS NOT NULL AND sub_entity_id IS NULL;
ALTER TABLE politician_entity DROP COLUMN entity_id;

COMMIT;
