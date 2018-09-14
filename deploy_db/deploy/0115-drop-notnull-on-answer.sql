-- Deploy mandatoaberto:0115-drop-notnull-on-answer to pg
-- requires: 0114-add-id-on-psp

BEGIN;

ALTER TABLE politician_knowledge_base ALTER COLUMN answer DROP NOT NULL;


COMMIT;
