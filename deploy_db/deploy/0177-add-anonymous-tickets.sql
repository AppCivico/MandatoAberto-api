-- Deploy mandatoaberto:0177-add-anonymous-tickets to pg
-- requires: 0176-add-custom_url

BEGIN;

ALTER TABLE ticket_type ADD COLUMN can_be_anonymous BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE ticket ADD COLUMN anonymous BOOLEAN NOT NULL DEFAULT FALSE;

COMMIT;
