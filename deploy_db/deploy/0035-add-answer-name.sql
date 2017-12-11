-- Deploy mandatoaberto:0035-add-answer-name to pg
-- requires: 0034-poll-results

BEGIN;

	ALTER TABLE direct_message ADD name text;

COMMIT;
