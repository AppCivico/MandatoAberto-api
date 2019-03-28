-- Deploy mandatoaberto:0161-update-icons_class to pg
-- requires: 0160-update-sub_modules

BEGIN;

UPDATE sub_module SET icon_class = 'fas fa-box' WHERE id = 8;
UPDATE sub_module SET icon_class = 'fas fa-chart-pie' WHERE id = 7;
UPDATE sub_module SET icon_class = 'fas fa-inbox' WHERE id = 3;

COMMIT;
