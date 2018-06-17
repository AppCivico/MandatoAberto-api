-- Deploy mandatoaberto:0081-add-fb_user_id-on-private_reply to pg
-- requires: 0080-add-picframe_url

BEGIN;

ALTER TABLE private_reply ADD COLUMN fb_user_id TEXT;

COMMIT;
