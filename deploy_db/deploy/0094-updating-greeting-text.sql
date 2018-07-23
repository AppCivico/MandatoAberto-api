-- Deploy mandatoaberto:0094-updating-greeting-text to pg
-- requires: 0093-add-platform

BEGIN;

UPDATE greeting
    SET content    = 'Olá, sou assistente digital do(a) ${user.office.name} ${user.name} Seja bem-vindo a nossa Rede! Queremos um Brasil melhor e precisamos de sua ajuda.',
        updated_at = now()
    WHERE id = 1;

COMMIT;
