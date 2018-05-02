-- Deploy mandatoaberto:0077-votolegal-integration to pg
-- requires: 0076-politician-chatbot-conversation

BEGIN;

CREATE TABLE politician_votolegal_integration (
    id              SERIAL    PRIMARY KEY,
    politician_id   INTEGER   REFERENCES politician(user_id) NOT NULL,
    votolegal_id    INTEGER   NOT NULL,
    votolegal_email TEXT      NOT NULL,
    website_url     TEXT      NOT NULL,
    created_at      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
