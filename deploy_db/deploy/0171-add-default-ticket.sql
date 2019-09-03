-- Deploy mandatoaberto:0171-add-default-ticket to pg
-- requires: 0170-add-questionnaire

BEGIN;

ALTER TABLE ticket
    ALTER COLUMN message SET DEFAULT '{}',
    ALTER COLUMN response SET DEFAULT '{}';

ALTER TABLE ticket
    ALTER COLUMN message SET NOT NULL,
    ALTER COLUMN message SET NOT NULL;

COMMIT;
