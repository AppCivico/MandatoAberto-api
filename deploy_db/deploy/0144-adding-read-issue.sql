-- Deploy mandatoaberto:0144-adding-read-issue to pg
-- requires: 0143-answers-conversion

BEGIN;

ALTER TABLE issue ADD COLUMN read BOOLEAN NOT NULL DEFAULT false;
UPDATE issue SET read = true;

COMMIT;
