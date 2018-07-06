-- Deploy mandatoaberto:0086-add-twitter to pg
-- requires: 0085-add-movement

BEGIN;

ALTER TABLE politician
    ADD COLUMN twitter_id           TEXT,
    ADD COLUMN twitter_oauth_token  TEXT,
    ADD COLUMN twitter_token_secret TEXT;

COMMIT;
