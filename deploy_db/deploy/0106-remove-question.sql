-- Deploy mandatoaberto:0106-remove-question to pg
-- requires: 0105-removing-entity-table

BEGIN;

ALTER TABLE politician_knowledge_base DROP COLUMN question;


COMMIT;
