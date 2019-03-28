-- Deploy mandatoaberto:0160-update-sub_modules to pg
-- requires: 0159-update-permissions

BEGIN;

DELETE FROM sub_module WHERE id IN (2, 3);
UPDATE sub_module SET icon_class = 'custom-icons board' WHERE id = 1;
UPDATE sub_module SET id = 2, icon_class = 'fas fas-user', url = '/dialogflow/intencoes' WHERE id = 4;
UPDATE sub_module SET id = 3, icon_class = 'fas fas-inbox', url = '/mensagens/caixa-de-entrada' WHERE id = 5;
UPDATE sub_module SET id = 4, icon_class = 'fas fa-paper-plane', url = '/mensagens/respondidas' WHERE id = 6;
UPDATE sub_module SET id = 5, icon_class = 'fas fa-trash-alt', url = '/mensagens/lixeira' WHERE id = 7;
UPDATE sub_module SET id = 6, icon_class = 'fas fa-bullhorn', url = '/engajamento/enviar-mensagen' WHERE id = 8;
UPDATE sub_module SET id = 7, icon_class = 'fas chart-pie', url = '/engajamento/enviar-enquete' WHERE id = 9;
UPDATE sub_module SET id = 8, icon_class = 'fas box', url = '/engajamento/enviados' WHERE id = 10;
UPDATE sub_module SET id = 9, icon_class = 'custom-icons users-plus', url = '/segmentacao/criar-grupos' WHERE id = 11;
UPDATE sub_module SET id = 10, icon_class = 'custom-icons users-group', url = '/segmentacao/meus-grupos' WHERE id = 12;
UPDATE sub_module SET id = 11, icon_class = 'fas fas-users', url = '/segmentacao/seguidores' WHERE id = 13;
UPDATE sub_module SET id = 12, icon_class = 'fas fas-scroll', url = '/logs/registro-de-atividades' WHERE id = 14;

COMMIT;
