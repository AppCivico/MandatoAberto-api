-- Deploy mandatoaberto:0121-add-active-bool to pg
-- requires: 0120-add-deleted-boolean

BEGIN;

ALTER TABLE politician_votolegal_integration ADD COLUMN active BOOLEAN NOT NULL DEFAULT true;

COMMIT;
