-- Deploy mandatoaberto:0071-updating-dialog-texts to pg
-- requires: 0070-updating-dialog

BEGIN;

UPDATE dialog SET name = 'Caixa de entrada', description = 'Aqui você cria a mensagem que seu assistente digital irá usar quando seus seguidores enviarem uma mensagem.' WHERE name = 'Fale conosco';
UPDATE question SET name = 'issue_acknowledgment', content = 'Como seu assistente deve estimular o envio de perguntas e mensagens de seus seguidores?' WHERE name = 'misunderstand';

COMMIT;
