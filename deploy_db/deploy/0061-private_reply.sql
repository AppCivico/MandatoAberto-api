-- Deploy mandatoaberto:0061-private_reply to pg
-- requires: 0060-recipient-opt_in-column

BEGIN;

CREATE TABLE private_reply (
    id            SERIAL PRIMARY KEY,
    politician_id INTEGER NOT NULL REFERENCES politician(user_id),
    item          TEXT   NOT NULL,
    post_id       TEXT   NOT NULL,
    comment_id    TEXT,
    permalink     TEXT    NOT NULL,
    reply_sent    BOOLEAN NOT NULL DEFAULT 'false',
    created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);
ALTER TABLE politician ADD COLUMN private_reply_activated BOOLEAN NOT NULL DEFAULT 'true';

COMMIT;
