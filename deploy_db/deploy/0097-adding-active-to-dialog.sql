-- Deploy mandatoaberto:0097-adding-active-to-dialog to pg
-- requires: 0096-adding-free-text-greeting

BEGIN;

ALTER TABLE dialog ADD COLUMN active BOOLEAN NOT NULL DEFAULT true;
UPDATE dialog SET active = false, updated_at = now() WHERE name = 'Quem sou eu';

COMMIT;
