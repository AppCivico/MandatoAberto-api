-- Deploy mandatoaberto:0107-removing-issues-from-kb to pg
-- requires: 0106-remove-question

BEGIN;

ALTER TABLE politician_knowledge_base DROP COLUMN issues;


COMMIT;
