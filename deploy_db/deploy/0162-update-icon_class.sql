-- Deploy mandatoaberto:0162-update-icon_class to pg
-- requires: 0161-update-icons_class

BEGIN;


UPDATE sub_module SET icon_class = 'fas fa-lightbulb' WHERE id = 2;
UPDATE sub_module SET icon_class = 'fas fa-users'     WHERE id = 11;
UPDATE sub_module SET icon_class = 'fas fa-scroll'    WHERE id = 12;

COMMIT;
