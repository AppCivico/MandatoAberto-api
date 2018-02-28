-- Deploy mandatoaberto:0017-politician-greetings to pg
-- requires: 0016-poll-active-boolean

BEGIN;

ALTER TABLE politician_greetings RENAME TO politician_greeting;

COMMIT;
