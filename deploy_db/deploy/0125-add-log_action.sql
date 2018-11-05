-- Deploy mandatoaberto:0125-add-log_action to pg
-- requires: 0124-add-log

BEGIN;

INSERT INTO log_action (id, name, has_field) VALUES (6, 'ENTITY_WAS_INCORRECT', 'true');

COMMIT;
