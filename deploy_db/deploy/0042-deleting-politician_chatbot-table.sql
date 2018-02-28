-- Deploy mandatoaberto:0042-deleting-politician_chatbot-table to pg
-- requires: 0041-poll-updated_at

BEGIN;

DROP TABLE politician_chatbot;

COMMIT;
