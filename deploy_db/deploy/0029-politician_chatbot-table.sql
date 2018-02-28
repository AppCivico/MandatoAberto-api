-- Deploy mandatoaberto:0029-politician_chatbot-table to pg
-- requires: 0028-chatbot-role

BEGIN;

CREATE TABLE politician_chatbot (
    user_id         INTEGER PRIMARY KEY REFERENCES "user"(id),
    politician_id   INTEGER NOT NULL REFERENCES politician(user_id)
);

COMMIT;
