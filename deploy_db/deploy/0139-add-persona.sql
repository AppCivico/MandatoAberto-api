-- Deploy mandatoaberto:0139-add-persona to pg
-- requires: 0138-add-is_mandatoaberto

BEGIN;

CREATE TABLE organization_chatbot_persona (
    id                      SERIAL PRIMARY KEY,
    organization_chatbot_id INTEGER REFERENCES organization_chatbot(id),
    name                    TEXT NOT NULL,
    facebook_id             TEXT NOT NULL,
    facebook_picture_url    TEXT NOT NULL,
    created_at              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
