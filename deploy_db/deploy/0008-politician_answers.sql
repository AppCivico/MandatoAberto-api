-- Deploy mandatoaberto:0008-politician_answers to pg
-- requires: 0007-question-content

BEGIN;

CREATE TABLE politician_answers (
    id          SERIAL  PRIMARY KEY,
    question_id INTEGER NOT NULL REFERENCES question(id),
    content     TEXT    NOT NULL
);

COMMIT;
