-- Deploy mandatoaberto:0095-add-dm-related to pg
-- requires: 0094-updating-greeting-text

BEGIN;

CREATE TABLE chatbot_available_dialogs (
    id              SERIAL PRIMARY KEY,
    name            TEXT   NOT NULL,
    translated_name TEXT   NOT NULL
);

INSERT INTO chatbot_available_dialogs (name, translated_name)
    VALUES ('greetings', 'Boas vindas'), ('aboutMe', 'Sobre mim'), ('poll', 'Enquete'),
           ('issue', 'Caixa de entrada'), ('contacts', 'Contatos'), ('votoLegal', 'Voto Legal'),
           ('listening', 'Aguardando mensagem para caixa de entrada'), ('mainMenu', 'Menu principal');

CREATE TABLE direct_message_attachment(
    id       SERIAL PRIMARY KEY,
    type     TEXT   NOT NULL,
    template TEXT,
    url      TEXT
);

ALTER TABLE direct_message
    ADD COLUMN type TEXT NOT NULL DEFAULT 'text',
    ADD COLUMN attachment_id INTEGER REFERENCES direct_message_attachment(id),
    ADD COLUMN quick_replies JSON,
    ALTER COLUMN content DROP NOT NULL,
    ALTER COLUMN count DROP NOT NULL,
    DROP COLUMN sent;

COMMIT;
