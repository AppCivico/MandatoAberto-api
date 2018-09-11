-- Deploy mandatoaberto:0100-add-dm-columns to pg
-- requires: 0099-add-entity-and-related-tables

BEGIN;

ALTER TABLE direct_message ADD COLUMN attachment_type TEXT, ADD COLUMN attachment_template TEXT, ADD COLUMN attachment_url TEXT;

COMMIT;
