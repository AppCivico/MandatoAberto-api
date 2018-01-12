-- Deploy mandatoaberto:0043-updating-party to pg
-- requires: 0042-deleting-politician_chatbot-table

BEGIN;

UPDATE party SET acronym = 'PSL', name = 'PARTIDO SOCIAL LIBERAL' WHERE id = 24;

COMMIT;
