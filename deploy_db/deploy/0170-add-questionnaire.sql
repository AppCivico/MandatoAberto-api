-- Deploy mandatoaberto:0170-add-questionnaire to pg
-- requires: 0169-add-ticket-data

BEGIN;

CREATE TABLE questionnaire_type (
    id   INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);
INSERT INTO questionnaire_type (id, name) VALUES (1, 'preparatory');

CREATE TABLE questionnaire_map (
    id         SERIAL PRIMARY KEY,
    type_id    INTEGER NOT NULL REFERENCES questionnaire_type(id),
    map        JSON   NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE questionnaire_question (
    id                   SERIAL     PRIMARY KEY,
    questionnaire_map_id INTEGER NOT NULL REFERENCES questionnaire_map(id),
    code                 VARCHAR(4) NOT NULL UNIQUE,
    type                 TEXT       NOT NULL CHECK ( type IN ( 'multiple_choice', 'open_text' ) ),
    text                 TEXT       NOT NULL,
    multiple_choices     JSON,
    extra_quick_replies  JSON,
    rules                JSON,
    send_flags           TEXT[],
    updated_at           TIMESTAMP WITHOUT TIME ZONE,
    created_at           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_type_multiple_choices CHECK ( (type = 'multiple_choice' AND multiple_choices IS NOT NULL) OR (type = 'open_text' AND multiple_choices IS NULL) ),
    CONSTRAINT question_type_check CHECK (type = ANY (ARRAY['multiple_choice'::text, 'open_text'::text]))
);

CREATE TABLE questionnaire_stash (
    id                   SERIAL PRIMARY KEY,
    recipient_id         INTEGER   NOT NULL REFERENCES recipient(id),
    questionnaire_map_id INTEGER   NOT NULL REFERENCES questionnaire_map(id),
    value                JSON      NOT NULL DEFAULT '{}',
    finished             BOOLEAN   NOT NULL DEFAULT FALSE,
    updated_at           TIMESTAMP WITHOUT TIME ZONE,
    created_at           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE( recipient_id, questionnaire_map_id )
);

CREATE TABLE questionnaire_answer (
    id                   SERIAL  PRIMARY KEY,
    recipient_id         INTEGER NOT NULL REFERENCES recipient(id),
    question_id          INTEGER NOT NULL REFERENCES questionnaire_question(id),
    questionnaire_map_id INTEGER NOT NULL REFERENCES questionnaire_map(id),
    answer_value         TEXT    NOT NULL,
    created_at           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE( recipient_id, question_id )
);

COMMIT;
