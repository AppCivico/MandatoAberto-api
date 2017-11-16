-- Deploy mandatoaberto:0016-poll-active-boolean to pg
-- requires: 0015-politician-greetings

BEGIN;

ALTER TABLE poll ADD COLUMN active BOOLEAN DEFAULT 'f';
UPDATE poll SET active = 'f';
ALTER TABLE poll ALTER COLUMN active SET NOT NULL;

COMMIT;
