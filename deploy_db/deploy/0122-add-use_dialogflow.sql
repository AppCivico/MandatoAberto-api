-- Deploy mandatoaberto:0122-add-use_dialogflow to pg
-- requires: 0121-add-active-bool

BEGIN;

ALTER TABLE politician ADD COLUMN use_dialogflow BOOLEAN NOT NULL DEFAULT false;
UPDATE politician SET use_dialogflow = true;

COMMIT;
