-- Deploy mandatoaberto:0087-movement_discount to pg
-- requires: 0086-add-twitter

BEGIN;

CREATE TABLE movement_discount (
    id          SERIAL       PRIMARY KEY,
    movement_id INTEGER      REFERENCES movement(id) NOT NULL,
    percentage  DECIMAL(5,2),
    amount      INTEGER,
    valid_until TIMESTAMP WITHOUT TIME ZONE NOT NULL default 'infinity'::timestamp without time zone,
    updated_at  TIMESTAMP WITHOUT TIME ZONE,
    created_at  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
