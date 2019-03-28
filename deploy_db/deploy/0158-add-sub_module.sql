-- Deploy mandatoaberto:0158-add-sub_module to pg
-- requires: 0157-remove-status_id

BEGIN;

CREATE TABLE sub_module (
    id              INTEGER PRIMARY KEY,
    module_id       INTEGER NOT NULL REFERENCES module(id),
    standard_weight INTEGER NOT NULL,
    name            TEXT NOT NULL UNIQUE,
    human_name      TEXT NOT NULL,
    url             TEXT NOT NULL,
    icon_class      TEXT NOT NULL,
    updated_at      TIMESTAMP WITHOUT TIME ZONE,
    created_at      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE( module_id, standard_weight )
);

ALTER TABLE module ADD COLUMN standard_weight INTEGER UNIQUE;
DELETE FROM organization_module WHERE module_id in (1, 2, 3);
DELETE FROM module WHERE id IN (1, 2, 3);

ALTER TABLE organization_module
    DROP CONSTRAINT organization_module_module_id_fkey,
    ADD FOREIGN KEY (module_id) REFERENCES module(id) ON UPDATE CASCADE;

INSERT INTO module (id, name, human_name, standard_weight) VALUES (1, 'general', 'Geral', 1);
UPDATE module SET id = 2, human_name = 'Dialogflow', standard_weight = 2 WHERE id = 4;
UPDATE module SET id = 3, standard_weight = 8 WHERE id = 5;
UPDATE module SET id = 4, standard_weight = 3 WHERE id = 6;
UPDATE module SET id = 5, human_name = 'Engajamento', standard_weight = 4 WHERE id = 7;
UPDATE module SET id = 6, human_name = 'Segmentação', standard_weight = 5 WHERE id = 8;
UPDATE module SET id = 7, standard_weight = 6 WHERE id = 9;
UPDATE module SET id = 8, human_name = 'Logs', standard_weight = 7 WHERE id = 10;

INSERT INTO organization_module (organization_id, module_id) SELECT id, 1 as module_id FROM organization;

INSERT INTO sub_module (id, module_id, standard_weight, name, human_name, url, icon_class) VALUES
    (1, 1,   1, 'metrics_list',      'Indicadores',            '/indicadores',            'fa fa-bullhorn'),
    (2, 1,   2, 'profile_list',      'Perfil',                 '/perfil',                 'fa fa-users'),
    (3, 1,   3, 'integrations_list', 'Integrações',            '/integracoes',            'fa fa-pie-chart'),
    (4, 2,   1, 'intents',           'Intenções',              '/intenções',              'fa fa-archive'),
    (5, 4,   1, 'issues_open',       'Caixa de Entrada',       '/mensagens-em-aberto',    'fa fa-archive'),
    (6, 4,   2, 'issues_closed',     'Respondidas',            '/mensagens-respondidas',  'fa fa-pie-chart'),
    (7, 4,   3, 'issues_deleted',    'Lixeira',                '/mensagens-deletadas',    'fa fa-file-text'),
    (8, 5,   1, 'campaign_dm',       'Enviar mensagem',        '/enviar-mensagem',        'fa fa-bullhorn'),
    (9, 5,   2, 'campaign_poll',     'Enviar enquete',         '/enviar-enquete',         'fa fa-pie-chart'),
    (10, 5,  3, 'campaign_list',     'Enviadas',               '/campanhas-enviadas',     'fa fa-file-text'),
    (11, 6,  1, 'group_create',      'Criar grupos',           '/criar-grupo',            'custom-icons users-plus'),
    (12, 6,  2, 'group_list',        'Meus grupos',            '/listar-grupo',           'custom-icons users-plus'),
    (13, 7,  1, 'recipients_list',   'Seguidores',             '/contatos',               'custom-icons users-group'),
    (14, 8, 1, 'log_list',          'Registro de atividades', '/registro-de-atividades', 'fa fa-file-text');

ALTER TABLE organization ADD COLUMN menu_config JSON;

COMMIT;
