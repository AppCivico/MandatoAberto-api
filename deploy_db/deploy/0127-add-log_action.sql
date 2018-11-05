-- Deploy mandatoaberto:0127-add-log_action to pg
-- requires: 0126-add-active-bool-on-flows

BEGIN;

INSERT INTO log_action (id, name, has_field) VALUES (7, 'INFORMED_CELLPHONE', false), (8, 'INFORMED_EMAIL', false);

COMMIT;
