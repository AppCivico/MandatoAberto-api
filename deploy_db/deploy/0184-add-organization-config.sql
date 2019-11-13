-- Deploy mandatoaberto:0184-add-organization-config to pg
-- requires: 0183-add-organization_ticket_type

BEGIN;

ALTER TABLE organization
    ADD COLUMN has_ticket          BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN has_email_broadcast BOOLEAN NOT NULL DEFAULT FALSE;

COMMIT;
