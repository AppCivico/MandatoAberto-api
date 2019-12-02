-- Deploy mandatoaberto:0186-add-fb_app_id to pg
-- requires: 0185-fix-anonymous-tickets

BEGIN;

ALTER TABLE organization ADD COLUMN fb_app_id TEXT;

COMMIT;
