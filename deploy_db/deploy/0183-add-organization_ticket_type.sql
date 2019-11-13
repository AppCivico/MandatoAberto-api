-- Deploy mandatoaberto:0183-add-organization_ticket_type to pg
-- requires: 0182-add-recipient-cpf

BEGIN;

CREATE TABLE organization_ticket_type (
    id              SERIAL  PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organization(id),
    ticket_type_id  INTEGER NOT NULL REFERENCES ticket_type(id),
    can_be_anonymous BOOLEAN NOT NULL DEFAULT false,
    description     TEXT,
    send_email_to   TEXT
);
INSERT INTO organization_ticket_type (organization_id, ticket_type_id)
SELECT
        o.organization_id as organization_id,
        t.id as ticket_type_id
    FROM ticket_type t, user_with_organization_data o
    WHERE email ILIKE '%dpo%';

ALTER TABLE ticket ADD COLUMN organization_ticket_type_id INTEGER REFERENCES organization_ticket_type(id);
UPDATE ticket t SET organization_ticket_type_id = sq.id
FROM (
    SELECT ot.id, ot.ticket_type_id FROM organization_ticket_type ot
) AS sq WHERE sq.ticket_type_id = t.type_id;

ALTER TABLE ticket
    DROP COLUMN type_id,
    ALTER COLUMN organization_ticket_type_id SET NOT NULL;

COMMIT;
