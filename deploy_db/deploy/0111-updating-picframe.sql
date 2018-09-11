-- Deploy mandatoaberto:0111-updating-picframe to pg
-- requires: 0110-add-boolean-on-question

BEGIN;

ALTER TABLE politician ADD COLUMN share_text TEXT;
ALTER TABLE politician RENAME picframe_url TO share_url;

COMMIT;
