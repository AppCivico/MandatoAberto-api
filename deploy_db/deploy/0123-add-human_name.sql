-- Deploy mandatoaberto:0123-add-human_name to pg
-- requires: 0122-add-use_dialogflow

BEGIN;

UPDATE politician_entity SET name = lower(name);
ALTER TABLE politician_entity ADD COLUMN human_name TEXT;

COMMIT;
