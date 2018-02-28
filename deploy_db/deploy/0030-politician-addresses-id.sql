-- Deploy mandatoaberto:0030-politician-addresses-id to pg
-- requires: 0029-politician_chatbot-table

BEGIN;

ALTER TABLE politician 
    ADD COLUMN address_state_id INTEGER REFERENCES state(id),
    ADD COLUMN address_city_id INTEGER REFERENCES city(id);

UPDATE politician as p SET address_state_id = s.id
    FROM state as s
    WHERE p.address_state = s.code;

UPDATE politician as p SET address_city_id = c.id
    FROM city as c
    WHERE p.address_city = c.name;

ALTER TABLE politician DROP COLUMN address_city, DROP COLUMN address_state;
ALTER TABLE politician 
	ALTER COLUMN address_city_id SET NOT NULL, 
	ALTER COLUMN address_state_id SET NOT NULL;

COMMIT;
