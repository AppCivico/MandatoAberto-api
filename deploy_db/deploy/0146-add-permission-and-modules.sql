-- Deploy mandatoaberto:0146-add-permission-and-modules to pg
-- requires: 0145-organization

BEGIN;

-- Creating new user_organization table
CREATE TABLE user_organization (
    id                   SERIAL PRIMARY KEY,
    user_id              INTEGER NOT NULL REFERENCES "user"(id),
    organization_id      INTEGER NOT NULL REFERENCES organization(id),
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

--- Fix: repeated organization_ids
ALTER TABLE organization ADD temp_id INTEGER;
WITH cte AS (
    SELECT
        u.id as user_id,
        u.organization_id,
        u.name,
        p.premium,
        p.premium_updated_at,
        u.approved,
        u.approved_at,
        ROW_NUMBER() OVER(PARTITION BY u.organization_id
                            ORDER BY u.organization_id ASC) as rk
    FROM
        "user" u,
        politician p
    WHERE u.id = p.user_id
)
INSERT INTO organization ( name, premium, premium_updated_at, approved, approved_at, temp_id ) SELECT c.name, c.premium, c.premium_updated_at, c.approved, c.approved_at, c.user_id as temp_id FROM cte c WHERE c.rk > 1;
UPDATE "user" me SET organization_id = o.id FROM organization o WHERE me.id = o.temp_id AND o.temp_id is not null;
ALTER TABLE organization DROP COLUMN temp_id;

-- Populating user_organization table
WITH cte AS (
    SELECT
        u.id as user_id,
        u.organization_id,
        ROW_NUMBER() OVER(PARTITION BY u.organization_id
                            ORDER BY u.organization_id ASC) as rk
    FROM
        "user" u
)
INSERT INTO user_organization (user_id, organization_id) SELECT c.user_id, c.organization_id  FROM cte c WHERE c.rk = 1 and c.user_id != 1;

ALTER TABLE "user" DROP COLUMN organization_id;

-- Creating module table and populating it
CREATE TABLE module (
    id         INTEGER PRIMARY KEY,
    name       TEXT    NOT NULL UNIQUE,
    human_name TEXT    NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);
INSERT INTO
    module (id, name, human_name)
VALUES
    (1,  'metrics', 'Indicadores'),
    (2,  'profile', 'Perfil'),
    (3,  'integrations', 'Integrações'),
    (4,  'entity', 'Temas'),
    (5,  'poll', 'Consultas'),
    (6,  'issue', 'Mensagens'),
    (7,  'campaign', 'Campanhas'),
    (8,  'group', 'Grupos'),
    (9,  'recipient', 'Seguidores'),
    (10, 'log', 'Registro de atividades');

CREATE TABLE organization_module (
    id              SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organization(id),
    module_id       INTEGER NOT NULL REFERENCES module(id),
    created_at      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

DELETE FROM user_role WHERE id = 3;
UPDATE role SET name = 'organization_admin' WHERE id = 3;

INSERT INTO
    role (id, name)
VALUES
    (4, 'organization_manager'),
    ( 6, 'metrics_create'),
    ( 7, 'metrics_read'),
    ( 8, 'metrics_update'),
    ( 9, 'metrics_delete'),
    ( 10, 'profile_create'),
    ( 11, 'profile_read'),
    ( 12, 'profile_update'),
    ( 13, 'profile_delete'),
    ( 14, 'integrations_create'),
    ( 15, 'integrations_read'),
    ( 16, 'integrations_update'),
    ( 17, 'integrations_delete'),
    ( 18, 'entity_create'),
    ( 19, 'entity_read'),
    ( 20, 'entity_update'),
    ( 21, 'entity_delete'),
    ( 22, 'entity_knowledge_base_create'),
    ( 23, 'entity_knowledge_base_read'),
    ( 24, 'entity_knowledge_base_update'),
    ( 25, 'entity_knowledge_base_delete'),
    ( 26, 'poll_create'),
    ( 27, 'poll_read'),
    ( 28, 'poll_update'),
    ( 29, 'poll_delete'),
    ( 30, 'issue_create'),
    ( 31, 'issue_read'),
    ( 32, 'issue_update'),
    ( 33, 'issue_delete'),
    ( 34, 'campaign_create'),
    ( 35, 'campaign_read'),
    ( 36, 'campaign_update'),
    ( 37, 'campaign_delete'),
    ( 38, 'group_create'),
    ( 39, 'group_read'),
    ( 40, 'group_update'),
    ( 41, 'group_delete'),
    ( 42, 'recipient_create'),
    ( 43, 'recipient_read'),
    ( 44, 'recipient_update'),
    ( 45, 'recipient_delete'),
    ( 46, 'log_create'),
    ( 47, 'log_read'),
    ( 48, 'log_update'),
    ( 49, 'log_delete');

COMMIT;
