-- Deploy mandatoaberto:0181-add-attachment to pg
-- requires: 0180-update-type

BEGIN;

ALTER TABLE organization ADD COLUMN email_header TEXT;

ALTER TABLE direct_message
    ADD COLUMN email_subject VARCHAR(78),
    ADD COLUMN email_attachment_file_name TEXT;
INSERT INTO campaign_type (name, human_name) VALUES ('email', 'Mensagem via e-mail');

COMMIT;
