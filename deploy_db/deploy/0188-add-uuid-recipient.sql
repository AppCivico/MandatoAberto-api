-- Deploy mandatoaberto:0188-add-uuid-recipient to pg
-- requires: 0187-add-ticket-response-interval

BEGIN;

ALTER TABLE recipient ADD COLUMN uuid uuid;

COMMIT;
