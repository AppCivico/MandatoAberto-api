-- Deploy mandatoaberto:0096-adding-free-text-greeting to pg
-- requires: 0095-add-dm-related

BEGIN;

ALTER TABLE politician_greeting ALTER COLUMN greeting_id DROP NOT NULL, ADD COLUMN on_facebook TEXT, ADD COLUMN on_website TEXT;
UPDATE politician_greeting SET on_facebook = sq.content, on_website = sq.content FROM ( SELECT content, id FROM greeting ) AS sq WHERE politician_greeting.greeting_id = sq.id;
ALTER TABLE politician_greeting ALTER COLUMN on_facebook SET NOT NULL, ALTER COLUMN on_website SET NOT NULL;

COMMIT;
