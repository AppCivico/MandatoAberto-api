-- Deploy mandatoaberto:0178-add-ticket-attachment to pg
-- requires: 0177-add-anonymous-tickets

BEGIN;


CREATE TABLE ticket_message (
    id                   SERIAL PRIMARY KEY,
    ticket_id            INTEGER REFERENCES ticket(id) NOT NULL,
    recipient_id         INTEGER REFERENCES recipient(id),
    user_id              INTEGER REFERENCES "user"(id),
    text                 TEXT    NOT NULL,
    created_by_recipient BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE ticket_attachment (
    id                  SERIAL  PRIMARY KEY,
    ticket_id           INTEGER REFERENCES ticket(id),
    ticket_message_id   INTEGER REFERENCES ticket_message(id),
    attached_to_message BOOLEAN NOT NULL DEFAULT FALSE,
    type                TEXT    NOT NULL,
    url                 TEXT    NOT NULL,
    created_at          TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);


COMMIT;
