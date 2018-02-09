-- Deploy mandatoaberto:0058-blacklist-facebook-messenger to pg
-- requires: 0057-group-deleted-at

BEGIN;

CREATE TABLE blacklist_facebook_messenger (
    id           SERIAL PRIMARY KEY,
    recipient_id INTEGER REFERENCES recipient(id) NOT NULL,
    created_at   TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
