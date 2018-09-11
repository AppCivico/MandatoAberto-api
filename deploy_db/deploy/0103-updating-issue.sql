-- Deploy mandatoaberto:0103-updating-issue to pg
-- requires: 0102-update-entity-structure

BEGIN;

ALTER TABLE issue ADD COLUMN peding_entity_recognition BOOLEAN DEFAULT false, ALTER COLUMN entities DROP NOT NULL;

COMMIT;
