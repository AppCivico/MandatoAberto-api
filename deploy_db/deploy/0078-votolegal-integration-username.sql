-- Deploy mandatoaberto:0078-votolegal-integration-username to pg
-- requires: 0077-votolegal-integration

BEGIN;

ALTER TABLE politician_votolegal_integration ADD COLUMN username TEXT;
UPDATE politician_votolegal_integration SET username = '';
ALTER TABLE politician_votolegal_integration ALTER COLUMN username SET NOT NULL;

COMMIT;
