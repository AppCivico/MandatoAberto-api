-- Deploy mandatoaberto:0028-chatbot-role to pg
-- requires: 0027-rename-page-acess-token

BEGIN;

INSERT INTO role (id, name) VALUES (3, 'chatbot');

COMMIT;
