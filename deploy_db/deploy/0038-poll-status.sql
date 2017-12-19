-- Deploy mandatoaberto:0038-poll-status to pg
-- requires: 0037-add-answer-name

BEGIN;

CREATE TABLE poll_status (
    id   INTEGER PRIMARY KEY,
    name TEXT    NOT NULL
);

INSERT INTO poll_status (id, name) VALUES (1, 'active'), (2, 'inactive'), (3, 'deactivated');

ALTER TABLE poll ADD COLUMN status_id INTEGER REFERENCES poll_status(id);
UPDATE poll SET status_id = 2;
ALTER TABLE poll ALTER COLUMN status_id SET NOT NULL;
ALTER TABLE poll DROP COLUMN active, DROP COLUMN activated_at;

COMMIT;
