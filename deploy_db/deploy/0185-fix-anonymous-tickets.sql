-- Deploy mandatoaberto:0185-fix-anonymous-tickets to pg
-- requires: 0184-add-organization-config

BEGIN;

UPDATE organization_ticket_type SET can_be_anonymous = 'TRUE'
FROM (SELECT id FROM ticket_type WHERE can_be_anonymous = TRUE) AS sq WHERE sq.id = ticket_type_id;

COMMIT;
