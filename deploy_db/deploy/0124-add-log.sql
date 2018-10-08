-- Deploy mandatoaberto:0124-add-log to pg
-- requires: 0123-add-human_name

BEGIN;

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
CREATE TABLE log_action (
    id        INTEGER PRIMARY KEY,
    name      TEXT    NOT NULL,
    has_field BOOLEAN NOT NULL
);

INSERT INTO log_action (id, name, has_field) VALUES (1, 'WENT_TO_FLOW', true), (2, 'ANSWERED_POLL', true), (3, 'ACTIVATED_NOTIFICATIONS', false), (4, 'DEACTIVATED_NOTIFICATIONS', false), (5, 'ASKED_ABOUT_ENTITY', true);

CREATE TABLE logs (
    timestamp     TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    politician_id INTEGER REFERENCES politician(user_id) NOT NULL,
    recipient_id  INTEGER REFERENCES recipient(id) NOT NULL,
    action_id     INTEGER REFERENCES log_action(id) NOT NULL,
    field_id      INTEGER
);
SELECT create_hypertable('logs', 'timestamp');

CREATE TABLE chatbot_steps (
    id         SERIAL PRIMARY KEY,
    payload    TEXT NOT NULL UNIQUE,
    human_name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
