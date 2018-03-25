-- Deploy mandatoaberto:0070-updating-dialog to pg
-- requires: 0069-updating-recipients-page_id

BEGIN;

UPDATE dialog SET description = 'Aqui você cria a mensagem "Fale Conosco" do seu assistente digital.', name = 'Fale conosco' WHERE name = 'Não entendi';
UPDATE question
    SET content = 'Escreva como seu assistente digital deve pedir para seus seguidores enviarem mensagens para sua equipe.',
    citizen_input = 'Fale conosco'
    WHERE name = 'misunderstand';
UPDATE question
    SET content = 'Como seu assistente digital deve responder para seus seguidores  quando a mensagem for enviada com sucesso?'
    WHERE name = 'issue_created';

COMMIT;
