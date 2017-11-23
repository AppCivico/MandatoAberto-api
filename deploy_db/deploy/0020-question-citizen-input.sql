-- Deploy mandatoaberto:0020-question-citizen-input to pg
-- requires: 0019-politician-greetings

BEGIN;

ALTER TABLE question ADD COLUMN citizen_input TEXT;
UPDATE question SET citizen_input = '';
ALTER TABLE question ALTER COLUMN citizen_input SET NOT NULL;

COMMIT;