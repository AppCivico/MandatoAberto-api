-- Deploy mandatoaberto:0099-add-entity-and-related-tables to pg
-- requires: 0098-updating-dialog-texts

BEGIN;

CREATE TABLE entity (
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

CREATE TABLE sub_entity (
    id         SERIAL  PRIMARY KEY,
    entity_id  INTEGER REFERENCES entity(id),
    name       TEXT    NOT NULL UNIQUE,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

CREATE TABLE politician_entity(
    id              SERIAL PRIMARY KEY,
    politician_id   INTEGER REFERENCES politician(user_id) NOT NULL,
    entity_id       INTEGER REFERENCES entity(id) NOT NULL,
    sub_entity_id   INTEGER REFERENCES sub_entity(id),
    recipient_count INTEGER NOT NULL,
    updated_at      TIMESTAMP WITHOUT TIME ZONE,
    created_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

ALTER TABLE recipient ADD COLUMN entities INTEGER[];
ALTER TABLE issue ADD COLUMN entities INTEGER[];

CREATE TABLE politician_knowledge_base (
    id            SERIAL    PRIMARY KEY,
    politician_id INTEGER   REFERENCES politician(user_id) NOT NULL,
    issues        INTEGER[] NOT NULL,
    entities      INTEGER[] NOT NULL,
    active        BOOLEAN   NOT NULL DEFAULT true,
    question      TEXT      NOT NULL,
    answer        TEXT      NOT NULL,
    updated_at    TIMESTAMP WITHOUT TIME ZONE,
    created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);


COMMIT;
