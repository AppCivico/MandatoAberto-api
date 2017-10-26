-- Deploy mandatoaberto:0007-question-content to pg
-- requires: 0006-question

BEGIN;

ALTER TABLE question ADD COLUMN content TEXT NOT NULL;

COMMIT;
