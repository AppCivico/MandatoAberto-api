-- Deploy mandatoaberto:0141-add-picture-chatbot to pg
-- requires: 0140-add-picture

BEGIN;

ALTER TABLE organization_chatbot ADD COLUMN picture TEXT;

COMMIT;
