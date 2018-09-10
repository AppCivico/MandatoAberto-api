-- Deploy mandatoaberto:0114-add-id-on-psp to pg
-- requires: 0113-add-poll_self_propagation

BEGIN;

ALTER TABLE poll_self_propagation_queue ADD COLUMN id SERIAL PRIMARY KEY;

COMMIT;
