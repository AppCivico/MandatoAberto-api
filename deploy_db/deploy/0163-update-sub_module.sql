-- Deploy mandatoaberto:0163-update-sub_module to pg
-- requires: 0162-update-icon_class

BEGIN;

UPDATE sub_module SET url = '/seguidores' WHERE id = 11;

COMMIT;
