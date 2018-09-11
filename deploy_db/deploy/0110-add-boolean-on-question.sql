-- Deploy mandatoaberto:0110-add-boolean-on-question to pg
-- requires: 0109-adding-media

BEGIN;

ALTER TABLE question ADD COLUMN active BOOLEAN NOT NULL DEFAULT true;

COMMIT;
