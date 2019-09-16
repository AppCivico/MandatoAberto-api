-- Deploy mandatoaberto:0176-add-custom_url to pg
-- requires: 0175-add-notification_bar

BEGIN;

ALTER TABLE organization ADD COLUMN custom_url TEXT;

COMMIT;
