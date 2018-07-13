-- Deploy mandatoaberto:0088-adding-one-movement to pg
-- requires: 0087-movement_discount

BEGIN;

INSERT INTO movement (name) VALUES ('Triunfo');

COMMIT;
