-- Deploy mandatoaberto:0159-update-permissions to pg
-- requires: 0158-add-sub_module

BEGIN;

UPDATE role SET name = 'general_profile_create' WHERE id = 10;
UPDATE role SET name = 'general_profile_read'   WHERE id = 11;
UPDATE role SET name = 'general_profile_update' WHERE id = 12;
UPDATE role SET name = 'general_profile_delete' WHERE id = 13;

COMMIT;
