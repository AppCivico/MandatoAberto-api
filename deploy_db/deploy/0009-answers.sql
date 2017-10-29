-- Deploy mandatoaberto:0009-answers to pg
-- requires: 0008-politician_answers

BEGIN;

DROP TABLE politician_answers;
CREATE TABLE answers (
    id          SERIAL  PRIMARY KEY,
    question_id INTEGER NOT NULL REFERENCES question(id),
    content     TEXT    NOT NULL
);

COMMIT;
