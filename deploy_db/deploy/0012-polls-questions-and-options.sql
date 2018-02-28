-- Deploy mandatoaberto:0012-polls-questions-and-options to pg
-- requires: 0011-politician-gender

BEGIN;

CREATE TABLE poll (
    id              SERIAL      PRIMARY KEY,
    politician_id   INTEGER     REFERENCES politician(user_id) NOT NULL
);

CREATE TABLE poll_questions (
    id      SERIAL  PRIMARY KEY,
    poll_id INTEGER REFERENCES poll(id) NOT NULL,
    content TEXT    NOT NULL
);

CREATE TABLE question_options (
    id          SERIAL  PRIMARY KEY,
    question_id INTEGER REFERENCES poll_questions(id) NOT NULL,
    content     TEXT NOT NULL
);

COMMIT;
