-- Deploy mandatoaberto:0031-office-gender to pg
-- requires: 0030-politician-addresses-id

BEGIN;

ALTER TABLE office ADD COLUMN gender TEXT;
UPDATE office SET gender = 'M';
ALTER TABLE office ALTER COLUMN gender SET NOT NULL;
ALTER TABLE office DROP CONSTRAINT office_name_key;
INSERT INTO office (name, gender) VALUES 
    ('Presidente', 'F'), ('Senadora', 'F'), ('Governadora', 'F'), ('Prefeita', 'F'),
    ('Deputada Federal', 'F'), ('Deputada Estadual', 'F'), ('Vereadora', 'F'), ('Candidata', 'F');

COMMIT;
