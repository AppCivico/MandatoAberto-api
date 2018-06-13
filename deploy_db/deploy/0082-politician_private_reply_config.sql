-- Deploy mandatoaberto:0082-politician_private_reply_config to pg
-- requires: 0081-add-fb_user_id-on-private_reply

BEGIN;

CREATE TABLE politician_private_reply_config (
    id                             SERIAL    PRIMARY KEY,
    politician_id                  INTEGER   NOT NULL REFERENCES politician(user_id) UNIQUE,
    active                         BOOLEAN   NOT NULL DEFAULT 'true',
    delay_between_private_replies  INTERVAL  NOT NULL DEFAULT '01:00:00',
    updated_at                     TIMESTAMP WITHOUT TIME ZONE
);

INSERT INTO politician_private_reply_config (politician_id) SELECT user_id FROM politician;

ALTER TABLE politician DROP COLUMN private_reply_activated;

COMMIT;
