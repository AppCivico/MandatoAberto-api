-- Deploy mandatoaberto:0034-poll-results to pg
-- requires: 0033-dialog-description

BEGIN;

CREATE TABLE poll_results (
    id         SERIAL  PRIMARY KEY,
    citizen_id INTEGER NOT NULL REFERENCES citizen(id),
    option_id  INTEGER NOT NULL REFERENCES question_options(id),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
