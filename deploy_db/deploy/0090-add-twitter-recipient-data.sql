-- Deploy mandatoaberto:0090-add-twitter-recipient-data to pg
-- requires: 0089-add-a-party

BEGIN;

ALTER TABLE recipient
    ALTER COLUMN fb_id DROP NOT NULL,
    ADD COLUMN twitter_id          TEXT,
    ADD COLUMN twitter_origin_id   TEXT,
    ADD COLUMN twitter_screen_name TEXT;

CREATE table recipient_network (
    recipient_id    INTEGER PRIMARY KEY REFERENCES recipient(id) UNIQUE,
    followers_count INTEGER NOT NULL DEFAULT 0,
    friends_count   INTEGER NOT NULL DEFAULT 0,
    updated_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

COMMIT;
