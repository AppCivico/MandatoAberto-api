-- Deploy mandatoaberto:0150-add-dialogflow-config to pg
-- requires: 0149-add-uniq-constraint

BEGIN;

--- Dialogflow
CREATE TABLE dialogflow_config(
    id                      SERIAL PRIMARY KEY,
    project_id              TEXT NOT NULL UNIQUE,
    credentials             JSON NOT NULL,
    created_at              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

--- The first dialogflow project is ours.
INSERT INTO dialogflow_config ( project_id, credentials ) VALUES ( 'mandato-aberto-copy', '{}' );

ALTER TABLE organization_chatbot_general_config DROP COLUMN dialogflow_project_id, ADD COLUMN dialogflow_config_id INTEGER REFERENCES dialogflow_config(id);

COMMIT;
