-- Deploy mandatoaberto:0032-citizen-contact-fields to pg
-- requires: 0031-office-gender

BEGIN;

ALTER TABLE citizen ADD COLUMN email TEXT, ADD COLUMN cellphone TEXT, ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();

COMMIT;
