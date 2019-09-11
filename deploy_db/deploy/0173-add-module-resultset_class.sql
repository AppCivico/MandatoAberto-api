-- Deploy mandatoaberto:0173-add-module-resultset_class to pg
-- requires: 0172-add-log-types

BEGIN;

ALTER TABLE module ADD COLUMN class TEXT;
UPDATE module SET class = 'Poll' WHERE name = 'poll';
UPDATE module SET class = 'Issue' WHERE name = 'issue';
UPDATE module SET class = 'Group' WHERE name = 'group';
UPDATE module SET class = 'Recipient' WHERE name = 'recipient';
UPDATE module SET class = 'Ticket' WHERE name = 'ticket';

COMMIT;
