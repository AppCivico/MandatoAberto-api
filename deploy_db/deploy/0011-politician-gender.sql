-- Deploy mandatoaberto:0011-politician-gender to pg
-- requires: 0010-politician_id-answers

BEGIN;

ALTER TABLE politician ADD COLUMN gender TEXT NOT NULL;

COMMIT;
