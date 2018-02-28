-- Deploy mandatoaberto:0039-greetings-correction to pg
-- requires: 0038-poll-status

BEGIN;

CREATE TABLE greeting (
    id         SERIAL PRIMARY KEY,
    content    TEXT NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITHOUT TIME ZONE
);

INSERT INTO greeting (content) VALUES 
    ('`Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja benvindo a nossa Rede! Queremos um Brasil a melhor e precisamos de sua ajuda.`'),
    ('`A equipe do(a) ${user.office.name} ${user.name} está com um novo canal de comunicação.`'),
    ('`Benvindo(a). Somos o time digital do(a) ${user.office.name} ${user.name}.`');

ALTER TABLE politician_greeting DROP COLUMN text;
ALTER TABLE politician_greeting ADD COLUMN greeting_id INTEGER REFERENCES greeting(id) NOT NULL DEFAULT 1;

COMMIT;
