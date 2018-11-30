-- Deploy mandatoaberto:0142-add-project_id to pg
-- requires: 0141-add-picture-chatbot

BEGIN;

ALTER TABLE organization_chatbot_general_config ADD COLUMN dialogflow_project_id TEXT;

COMMIT;
