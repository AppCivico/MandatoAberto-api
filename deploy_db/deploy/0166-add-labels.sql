-- Deploy mandatoaberto:0166-add-labels to pg
-- requires: 0165-remove-ignored

BEGIN;

CREATE TABLE label (
    id                      SERIAL PRIMARY KEY,
    organization_chatbot_id INTEGER NOT NULL REFERENCES organization_chatbot(id),
    name                    TEXT    NOT NULL,
    updated_at              TIMESTAMP WITHOUT TIME ZONE,
    created_at              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(organization_chatbot_id, name)
);

CREATE TABLE recipient_label (
    recipient_id INTEGER NOT NULL REFERENCES recipient(id),
    label_id     INTEGER NOT NULL REFERENCES label(id),
    UNIQUE(recipient_id, label_id)
);

COMMIT;
