-- Deploy mandatoaberto:0179-add-organization_dialog to pg
-- requires: 0178-add-ticket-attachment

BEGIN;

CREATE TABLE organization_dialog (
    id              SERIAL  PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organization(id),
    name            TEXT    NOT NULL,
    description     TEXT    NOT NULL,
    dialog_id       INTEGER NOT NULL references dialog(id),
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

INSERT INTO organization_dialog (organization_id, name, description, dialog_id)
SELECT
    o.id as organization_id,
    d.name,
    d.description,
    d.id as dialog_id
FROM
    organization o,
    dialog d;


CREATE TABLE organization_question (
    id                     SERIAL  PRIMARY KEY,
    organization_dialog_id INTEGER NOT NULL REFERENCES organization_dialog(id),
    name                   TEXT    NOT NULL,
    content                TEXT    NOT NULL,
    citizen_input          TEXT    NOT NULL,
    active                 BOOLEAN NOT NULL DEFAULT TRUE,
    question_id            INTEGER REFERENCES question(id),
    created_at             TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

INSERT INTO organization_question (organization_dialog_id, name, content, citizen_input, question_id)
SELECT
    d.id as organization_dialog_id,
    q.name,
    q.content,
    q.citizen_input,
    q.id as question_id
FROM
    organization o,
    organization_dialog d,
    question q
WHERE
    o.id = d.organization_id
    AND q.dialog_id = d.dialog_id;

ALTER TABLE answer ADD COLUMN organization_question_id INTEGER REFERENCES organization_question(id);
UPDATE answer a SET organization_question_id = sq.id
FROM (
    SELECT q.id, q.question_id, d.organization_id, u.chatbot_id
    FROM
    organization_question q, organization_dialog d, user_with_organization_data u
    WHERE d.id = q.organization_dialog_id AND u.organization_id = d.organization_id
) AS sq WHERE a.question_id = sq.question_id AND a.organization_chatbot_id = sq.chatbot_id;

ALTER TABLE organization_dialog DROP COLUMN dialog_id;
ALTER TABLE organization_question DROP COLUMN question_id;
ALTER TABLE answer DROP COLUMN question_id;

COMMIT;
