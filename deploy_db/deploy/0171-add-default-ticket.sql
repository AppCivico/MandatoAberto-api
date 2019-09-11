-- Deploy mandatoaberto:0171-add-default-ticket to pg
-- requires: 0170-add-questionnaire

BEGIN;

ALTER TABLE ticket
    ALTER COLUMN message SET DEFAULT '{}',
    ALTER COLUMN response SET DEFAULT '{}';

UPDATE ticket SET response = '{}' WHERE response IS NULL;
UPDATE ticket SET message = '{}' WHERE message IS NULL;

ALTER TABLE ticket
    ALTER COLUMN response SET NOT NULL,
    ALTER COLUMN message SET NOT NULL;

COMMIT;
