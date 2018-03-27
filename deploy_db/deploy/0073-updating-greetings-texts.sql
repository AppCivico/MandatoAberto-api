-- Deploy mandatoaberto:0073-updating-greetings-texts to pg
-- requires: 0072-add-other-office

BEGIN;

UPDATE greeting SET content = 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil a melhor e precisamos de sua ajuda.' WHERE id = 1;
UPDATE greeting SET content = 'Bem-vindo(a). Somos o time digital do(a) ${user.office.name} ${user.name}.' WHERE id = 3;


COMMIT;
