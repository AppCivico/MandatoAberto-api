-- Deploy mandatoaberto:0050-tag-hstore to pg
-- requires: 0049-add-tag

BEGIN;

-- CREATE EXTENSION hstore;
ALTER TABLE recipient ADD COLUMN tags HSTORE DEFAULT '';

COMMIT;
