-- Deploy mandatoaberto:0182-add-recipient-cpf to pg
-- requires: 0181-add-attachment

BEGIN;

ALTER TABLE recipient ADD COLUMN cpf TEXT;

COMMIT;
