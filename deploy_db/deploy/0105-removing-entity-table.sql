-- Deploy mandatoaberto:0105-removing-entity-table to pg
-- requires: 0104-updating-entity-and-issue-structure

BEGIN;

DELETE FROM politician_entity;
ALTER TABLE politician_entity ADD COLUMN name TEXT NOT NULL, DROP COLUMN entity_id;
DROP TABLE entity;

COMMIT;
