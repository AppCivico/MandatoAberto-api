-- Deploy mandatoaberto:0132-update-campaign to pg
-- requires: 0131-improving-config-trigger

BEGIN;

ALTER TABLE direct_message DROP COLUMN politician_id, DROP COLUMN created_at;

CREATE TABLE campaign_status (
    id   INTEGER PRIMARY KEY,
    name TEXT    NOT NULL
);
INSERT INTO campaign_status (id, name) VALUES (1, 'processing'), (2, 'sent'), (3, 'error');

ALTER TABLE campaign ADD COLUMN status_id INTEGER REFERENCES campaign_status(id) NOT NULL DEFAULT 1;
ALTER TABLE campaign ADD COLUMN count INTEGER;
ALTER TABLE campaign ADD COLUMN groups INTEGER[];
UPDATE campaign AS c SET count = dm.count FROM direct_message AS dm WHERE c.id = dm.campaign_id;
UPDATE campaign AS c SET groups = dm.groups FROM direct_message AS dm WHERE c.id = dm.campaign_id;
UPDATE campaign AS c SET groups = pp.groups FROM poll_propagate AS pp WHERE c.id = pp.campaign_id;
ALTER TABLE campaign ALTER COLUMN count SET NOT NULL;

ALTER TABLE direct_message DROP COLUMN count;
ALTER TABLE direct_message DROP COLUMN groups;

UPDATE campaign SET status_id = 2;

COMMIT;
