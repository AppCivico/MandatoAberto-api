-- Deploy mandatoaberto:0033-dialog-description to pg
-- requires: 0032-citizen-contact-fields

BEGIN;

ALTER TABLE dialog ADD COLUMN description TEXT;
UPDATE dialog SET description = '';
ALTER TABLE dialog ALTER COLUMN description SET NOT NULL;

COMMIT;
