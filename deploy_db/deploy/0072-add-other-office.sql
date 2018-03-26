-- Deploy mandatoaberto:0072-add-other-office to pg
-- requires: 0071-updating-dialog-texts

BEGIN;

INSERT INTO office (name, gender) VALUES ('Outros', 'M'), ('Outros', 'F');

COMMIT;
