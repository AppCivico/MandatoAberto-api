-- Deploy mandatoaberto:0089-add-a-party to pg
-- requires: 0088-adding-one-movement

BEGIN;

INSERT INTO party (name, acronym) VALUES ('PODEMOS', 'PODEMOS');

COMMIT;
