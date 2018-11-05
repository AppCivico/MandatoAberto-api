-- Deploy mandatoaberto:0129-updating-logs to pg
-- requires: 0128-add-adaptive-chunking

BEGIN;

ALTER TABLE logs ALTER COLUMN recipient_id DROP NOT NULL;

ALTER TABLE log_action ADD COLUMN is_recipient BOOLEAN;
UPDATE log_action SET is_recipient = true;
ALTER TABLE log_action ALTER COLUMN is_recipient SET NOT NULL;

INSERT INTO log_action (id, name, has_field, is_recipient)
    VALUES (9, 'UPDATED_POLITICIAN_PROFILE', false, false), (10, 'UPDATED_GREETINGS', false, false),
    (11, 'UPDATED_CONTACTS', false, false), (12, 'UPDATED_ANSWER', true, false),
    (13, 'UPDATED_KNOWLEDGE_BASE', true, false), (14, 'CREATED_POLL', true, false),
    (15, 'ACTIVATED_POLL', true, false), (16, 'ANSWERED_ISSUE', true, false),
    (17, 'IGNORED_ISSUE', true, false), (18, 'DELETED_ISSUE', true, false),
    (19, 'SENT_CAMPAIGN', true, false), (20, 'CREATED_GROUP', true, false),
    (21, 'UPDATED_GROUP', true, false), (22, 'DELETED_GROUP', true, false),
    (23, 'ADDED_RECIPIENT_TO_GROUP', true, false);

ALTER TABLE campaign_type ADD COLUMN human_name TEXT;
UPDATE campaign_type SET human_name = 'mensagem no Facebook' WHERE id = 1;
UPDATE campaign_type SET human_name = 'consulta no Facebook' WHERE id = 2;
ALTER TABLE campaign_type ALTER COLUMN human_name SET NOT NULL;

COMMIT;
