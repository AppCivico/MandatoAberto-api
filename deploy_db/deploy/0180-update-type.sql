-- Deploy mandatoaberto:0180-update-type to pg
-- requires: 0179-add-organization_dialog

BEGIN;

ALTER TABLE ticket_attachment ALTER COLUMN type DROP NOT NULL;

COMMIT;
