-- Deploy mandatoaberto:0116-add-available_types to pg
-- requires: 0115-drop-notnull-on-answer

BEGIN;

CREATE TABLE available_types (
    id         INTEGER   PRIMARY KEY,
    name       TEXT      NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);
INSERT into available_types (id, name) VALUES (1, 'posicionamento'), (2, 'proposta'), (3, 'histórico');

ALTER TABLE politician_knowledge_base ADD COLUMN type TEXT NOT NULL DEFAULT 'posicionamento';

COMMIT;
