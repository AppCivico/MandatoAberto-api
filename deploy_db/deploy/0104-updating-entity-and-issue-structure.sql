-- Deploy mandatoaberto:0104-updating-entity-and-issue-structure to pg
-- requires: 0103-updating-issue

BEGIN;

ALTER TABLE politician_entity DROP COLUMN sub_entity_id;
ALTER TABLE politician_entity ADD COLUMN entity_id INTEGER REFERENCES entity(id);
DROP TABLE sub_entity;

COMMIT;
