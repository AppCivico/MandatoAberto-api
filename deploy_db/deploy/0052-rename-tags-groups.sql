-- Deploy mandatoaberto:0052-rename-tags-groups to pg
-- requires: 0051-tag-recipients-count

BEGIN;

ALTER TABLE tag RENAME TO "group";
ALTER TABLE recipient RENAME COLUMN tags TO groups;

COMMIT;
