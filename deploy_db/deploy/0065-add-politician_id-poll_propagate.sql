-- Deploy mandatoaberto:0065-add-politician_id-poll_propagate to pg
-- requires: 0064-add-campaign

BEGIN;

ALTER TABLE poll_propagate ADD COLUMN politician_id INTEGER REFERENCES politician(user_id);
UPDATE poll_propagate SET politician_id = 0;
ALTER TABLE poll_propagate ALTER COLUMN politician_id SET NOT NULL;

COMMIT;
