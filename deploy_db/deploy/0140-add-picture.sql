-- Deploy mandatoaberto:0140-add-picture to pg
-- requires: 0139-add-persona

BEGIN;

ALTER TABLE organization ADD COLUMN picture TEXT;
ALTER TABLE "user" ADD COLUMN picture TEXT;
ALTER TABLE organization_chatbot ADD COLUMN name TEXT;

COMMIT;
