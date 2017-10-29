-- Deploy mandatoaberto:0010-politician_id-answers to pg
-- requires: 0009-answers

BEGIN;

ALTER TABLE answers ADD COLUMN politician_id INTEGER NOT NULL REFERENCES politician(user_id);

COMMIT;
