-- Deploy mandatoaberto:0157-remove-status_id to pg
-- requires: 0156-add-invite-token

BEGIN;

ALTER TABLE poll DROP COLUMN status_id;

COMMIT;
