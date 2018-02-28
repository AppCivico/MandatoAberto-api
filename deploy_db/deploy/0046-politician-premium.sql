-- Deploy mandatoaberto:0046-politician-premium to pg
-- requires: 0045-removing-fb_app_secret-fb_app_id

BEGIN;

ALTER TABLE politician ADD COLUMN premium BOOLEAN NOT NULL DEFAULT FALSE, ADD COLUMN premium_updated_at TIMESTAMP WITHOUT TIME ZONE;

COMMIT;
