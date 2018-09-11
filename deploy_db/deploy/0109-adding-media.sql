-- Deploy mandatoaberto:0109-adding-media to pg
-- requires: 0108-add-saved_attachment_id

BEGIN;

ALTER TABLE issue ADD COLUMN saved_attachment_id TEXT, ADD COLUMN saved_attachment_type TEXT;
ALTER TABLE politician_knowledge_base ADD COLUMN saved_attachment_id TEXT, ADD COLUMN saved_attachment_type TEXT;

COMMIT;
