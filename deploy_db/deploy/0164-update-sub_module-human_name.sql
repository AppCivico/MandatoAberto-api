-- Deploy mandatoaberto:0164-update-sub_module-human_name to pg
-- requires: 0163-update-sub_module

BEGIN;

UPDATE sub_module SET human_name = 'Caixa de entrada' WHERE id = 3;

COMMIT;
