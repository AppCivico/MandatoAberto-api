-- Deploy mandatoaberto:0076-politician-chatbot-conversation to pg
-- requires: 0075-setting-created_by_admin_id-notnull

BEGIN;

ALTER TABLE recipient ADD COLUMN session JSON, ADD COLUMN session_updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW();
CREATE TABLE politician_chatbot_conversation (
    id                 SERIAL    PRIMARY KEY,
    politician_id      INTEGER   REFERENCES politician(user_id) NOT NULL,
    conversation_model TEXT      NOT NULL,
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP WITHOUT TIME ZONE
);

COMMIT;
