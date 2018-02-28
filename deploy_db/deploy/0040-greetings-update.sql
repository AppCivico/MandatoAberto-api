-- Deploy mandatoaberto:0040-greetings-update to pg
-- requires: 0039-greetings-correction

BEGIN;

UPDATE greeting SET content = 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja benvindo a nossa Rede! Queremos um Brasil a melhor e precisamos de sua ajuda.', updated_at = NOW() where id = 1;
UPDATE greeting SET content = 'A equipe do(a) ${user.office.name} ${user.name} está com um novo canal de comunicação.', updated_at = NOW() where id = 2;
UPDATE greeting SET content = 'Benvindo(a). Somos o time digital do(a) ${user.office.name} ${user.name}.', updated_at = NOW() where id = 3;

COMMIT;
