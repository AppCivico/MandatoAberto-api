-- Deploy mandatoaberto:0155-improving-organization-structure to pg
-- requires: 0154-poll_propagate

BEGIN;

ALTER TABLE
    recipient
DROP COLUMN origin_dialog,
DROP COLUMN twitter_id,
DROP COLUMN twitter_origin_id,
DROP COLUMN twitter_screen_name,
DROP COLUMN platform;

ALTER TABLE politician
DROP COLUMN twitter_id,
DROP COLUMN twitter_oauth_token,
DROP COLUMN twitter_token_secret,
DROP COLUMN issue_active,
DROP COLUMN use_dialogflow;

DROP TABLE recipient_network;
DROP TABLE poll_notification;

COMMIT;
