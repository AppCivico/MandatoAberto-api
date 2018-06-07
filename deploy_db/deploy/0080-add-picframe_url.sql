-- Deploy mandatoaberto:0080-add-picframe_url to pg
-- requires: 0079-add-new-office

BEGIN;

ALTER TABLE politician ADD COLUMN picframe_url TEXT;

COMMIT;
