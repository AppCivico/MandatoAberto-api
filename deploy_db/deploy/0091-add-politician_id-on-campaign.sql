-- Deploy mandatoaberto:0091-add-politician_id-on-campaign to pg
-- requires: 0090-add-twitter-recipient-data

BEGIN;

ALTER TABLE campaign ADD COLUMN politician_id INTEGER REFERENCES politician(user_id);
UPDATE campaign SET politician_id = ( SELECT politician_id FROM direct_message WHERE campaign_id = campaign.id ) WHERE type_id = 1;
UPDATE campaign SET politician_id = ( SELECT politician_id FROM poll_propagate WHERE campaign_id = campaign.id ) WHERE politician_id IS NULL;
ALTER TABLE campaign ALTER COLUMN politician_id SET NOT NULL;

COMMIT;
