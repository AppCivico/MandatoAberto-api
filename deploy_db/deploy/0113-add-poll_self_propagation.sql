-- Deploy mandatoaberto:0113-add-poll_self_propagation to pg
-- requires: 0112-add-poll_notification

BEGIN;

ALTER TABLE poll ADD COLUMN notification_sent BOOLEAN NOT NULL DEFAULT false;
UPDATE poll SET notification_sent = true;

CREATE TABLE poll_self_propagation_config (
    id            SERIAL    PRIMARY KEY,
    politician_id INTEGER   REFERENCES politician(user_id) NOT NULL UNIQUE,
    active        BOOLEAN   NOT NULL DEFAULT false,
    send_after    INTERVAL  NOT NULL DEFAULT '02:00:00',
    updated_at    TIMESTAMP WITHOUT TIME ZONE
);
INSERT INTO poll_self_propagation_config (politician_id) SELECT user_id FROM politician;

CREATE TABLE poll_self_propagation_queue (
    poll_id      INTEGER   NOT NULL REFERENCES poll(id),
    recipient_id INTEGER   NOT NULL REFERENCES recipient(id),
    sent         BOOLEAN   NOT NULL DEFAULT false,
    sent_at      TIMESTAMP WITHOUT TIME ZONE
);

COMMIT;
