-- Deploy mandatoaberto:0026-removing-politicianid-dmqueue to pg
-- requires: 0025-direct-message-table

BEGIN;

ALTER TABLE direct_message_queue DROP COLUMN politician_id;

COMMIT;
