-- Deploy mandatoaberto:0079-add-new-office to pg
-- requires: 0078-votolegal-integration-username

BEGIN;

INSERT INTO office (name, gender) VALUES ('pré-candidato', 'M'), ('pré-candidata', 'F');

COMMIT;
