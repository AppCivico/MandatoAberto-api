-- Deploy mandatoaberto:0001-politian-party-office-tables to pg
-- requires: 0000-appschema

BEGIN;

UPDATE role SET name = 'politian' WHERE ID = 2;

CREATE TABLE party
(
    id      SERIAL PRIMARY KEY,
    acronym TEXT   NOT NULL,
    name    TEXT
);

INSERT INTO party (acronym, name) VALUES
    ('PMDB', 'PARTIDO DO MOVIMENTO DEMOCRÁTICO BRASILEIRO'),
    ('PTB', 'PARTIDO TRABALHISTA BRASILEIRO'),
    ('PDT', 'PARTIDO DEMOCRÁTICO TRABALHISTA'),
    ('PT', 'PARTIDO DOS TRABALHADORES'),
    ('DEM', 'DEMOCRATAS'),
    ('PCdoB', 'PARTIDO COMUNISTA DO BRASIL'),
    ('PSB', 'PARTIDO SOCIALISTA BRASILEIRO'),
    ('PSDB', 'PARTIDO DA SOCIAL DEMOCRACIA BRASILEIRA'),
    ('PTC', 'PARTIDO TRABALHISTA CRISTÃO'),
    ('PSC', 'PARTIDO SOCIAL CRISTÃO'),
    ('PMN', 'PARTIDO DA MOBILIZAÇÃO NACIONAL'),
    ('PRP', 'PARTIDO REPUBLICANO PROGRESSISTA'),
    ('PPS', 'PARTIDO POPULAR SOCIALISTA'),
    ('PV', 'PARTIDO VERDE'),
    ('PTdoB', 'PARTIDO TRABALHISTA DO BRASIL'),
    ('PP', 'PARTIDO PROGRESSISTA'),
    ('PSTU', 'PARTIDO SOCIALISTA DOS TRABALHADORES UNIFICADO'),
    ('PCB', 'PARTIDO COMUNISTA BRASILEIRO'),
    ('PRTB', 'PARTIDO RENOVADOR TRABALHISTA BRASILEIRO'),
    ('PHS', 'PARTIDO HUMANISTA DA SOLIDARIEDADE'),
    ('PSDC', 'PARTIDO SOCIAL DEMOCRATA CRISTÃO'),
    ('PCO', 'PARTIDO DA CAUSA OPERÁRIA'),
    ('PTN', 'PARTIDO TRABALHISTA NACIONAL'),
    ('Livres', 'LIVRES'),
    ('PRB', 'PARTIDO REPUBLICANO BRASILEIRO'),
    ('PSOL', 'PARTIDO SOCIALISMO E LIBERDADE'),
    ('PR', 'PARTIDO DA REPÚBLICA'),
    ('PSD', 'PARTIDO SOCIAL DEMOCRÁTICO'),
    ('PPL', 'PARTIDO PÁTRIA LIVRE'),
    ('PEN', 'PARTIDO ECOLÓGICO NACIONAL'),
    ('PROS', 'PARTIDO REPUBLICANO DA ORDEM SOCIAL'),
    ('SD', 'SOLIDARIEDADE'),
    ('NOVO', 'PARTIDO NOVO'),
    ('REDE', 'REDE SUSTENTABILIDADE'),
    ('PMB', 'PARTIDO DA MULHER BRASILEIRA');

CREATE TABLE office (
    id   SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

INSERT INTO office (name) VALUES
    ('Presidente'), ('Senador'), ('Governador'), ('Prefeito'),
    ('Deputado Federal'), ('Deputado Estadual'), ('Vereador'), ('Candidato');


CREATE TABLE politian
(
    id                  SERIAL  PRIMARY KEY,
    user_id             INTEGER NOT NULL REFERENCES "user"(id),
    name                TEXT    NOT NULL,
    address_state       TEXT    NOT NULL,
    address_city        TEXT    NOT NULL,
    party_id            INTEGER NOT NULL REFERENCES party(id),
    office_id           INTEGER NOT NULL REFERENCES office(id),
    fb_page_id          TEXT,
    fb_app_id           TEXT,
    fb_app_secret       TEXT,
    fb_page_acess_token TEXT,
    approved            BOOLEAN NOT NULL DEFAULT FALSE,
    approved_at         TIMESTAMP WITHOUT TIME ZONE
);

COMMIT;
