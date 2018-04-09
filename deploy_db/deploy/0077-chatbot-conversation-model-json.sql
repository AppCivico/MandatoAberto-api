-- Deploy mandatoaberto:0077-chatbot-conversation-model-json to pg
-- requires: 0076-politician-chatbot-conversation

BEGIN;

ALTER TABLE politician_chatbot_conversation ALTER COLUMN conversation_model TYPE JSON using conversation_model::JSON;

COMMIT;
