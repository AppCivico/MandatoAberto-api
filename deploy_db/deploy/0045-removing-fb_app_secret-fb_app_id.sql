-- Deploy mandatoaberto:0045-removing-fb_app_secret-fb_app_id to pg
-- requires: 0044-adding-url-to-politician_contact

BEGIN;

ALTER TABLE politician DROP COLUMN fb_app_id, DROP COLUMN fb_app_secret;

COMMIT;
