-- Deploy mandatoaberto:0172-add-log-types to pg
-- requires: 0171-add-default-ticket

BEGIN;

INSERT INTO ticket_log_action (id, code) VALUES (5, 'ticket nova resposta'), (6, 'ticket nova mensagem');

COMMIT;
