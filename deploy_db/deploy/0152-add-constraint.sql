-- Deploy mandatoaberto:0152-add-constraint to pg
-- requires: 0151-create-view

BEGIN;

ALTER TABLE politician_entity ADD CONSTRAINT chatbot_id_name UNIQUE (organization_chatbot_id, name);


COMMIT;
