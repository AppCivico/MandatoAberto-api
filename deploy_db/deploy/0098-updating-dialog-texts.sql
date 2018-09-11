-- Deploy mandatoaberto:0098-updating-dialog-texts to pg
-- requires: 0097-adding-active-to-dialog

BEGIN;

UPDATE dialog SET description = 'Configuração de diálogos padrões do assistente.', name = 'Frases padrões' WHERE name = 'Caixa de entrada';
UPDATE question SET content = 'Mensagem padrão para esclarecer o funcionamento do assistente digital para o seu público.' WHERE name = 'issue_acknowledgment';
UPDATE question SET content = 'Mensagem para agradecer o envio de mensagem para a caixa de entrada, e dizer qual será o tempo médio de resposta por exemplo.' WHERE name = 'issue_created';

COMMIT;
