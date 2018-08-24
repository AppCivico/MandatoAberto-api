-- Deploy mandatoaberto:0108-add-saved_attachment_id to pg
-- requires: 0107-removing-issues-from-kb

BEGIN;

ALTER TABLE direct_message ADD COLUMN saved_attachment_id TEXT, DROP COLUMN attachment_id;

COMMIT;
