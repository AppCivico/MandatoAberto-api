-- Deploy mandatoaberto:0167-add-ticket to pg
-- requires: 0166-add-labels

BEGIN;

CREATE TABLE ticket_type (
    id   INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
INSERT INTO ticket_type (id, name) VALUES (1, 'Pedido 1'), (2, 'Pedido 2');

CREATE TABLE ticket (
    id                      SERIAL PRIMARY KEY,
    organization_chatbot_id INTEGER NOT NULL REFERENCES organization_chatbot(id),
    recipient_id            INTEGER NOT NULL REFERENCES recipient(id),
    type_id                 INTEGER NOT NULL REFERENCES ticket_type(id),
    assignee_id             INTEGER REFERENCES "user"(id),
    assigned_by             INTEGER REFERENCES "user"(id),
    status                  TEXT    NOT NULL CHECK (status = 'pending' OR status = 'closed' OR status = 'progress'),
    assigned_at             TIMESTAMP WITHOUT TIME ZONE,
    message                 TEXT[],
    response                TEXT[],
    progress_started_at     TIMESTAMP WITHOUT TIME ZONE,
    closed_at               TIMESTAMP WITHOUT TIME ZONE,
    status_last_updated_at  TIMESTAMP WITHOUT TIME ZONE,
    created_at              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
