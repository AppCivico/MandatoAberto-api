-- Deploy mandatoaberto:0060-recipient-opt_in-column to pg
-- requires: 0059-add-group-status-error

BEGIN;

ALTER TABLE recipient ADD COLUMN fb_opt_in BOOLEAN NOT NULL DEFAULT 't';

COMMIT;
