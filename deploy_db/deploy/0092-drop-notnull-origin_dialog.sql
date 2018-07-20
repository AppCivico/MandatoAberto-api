-- Deploy mandatoaberto:0092-drop-notnull-origin_dialog to pg
-- requires: 0091-add-politician_id-on-campaign

BEGIN;

ALTER TABLE recipient ALTER COLUMN origin_dialog DROP NOT NULL;

COMMIT;
