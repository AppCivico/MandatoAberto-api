-- Deploy mandatoaberto:0149-add-uniq-constraint to pg
-- requires: 0148-add-unique-module

BEGIN;

ALTER TABLE user_organization ADD CONSTRAINT user_organization_unique UNIQUE (organization_id, user_id);


COMMIT;
