-- Deploy mandatoaberto:0064-add-campaign to pg
-- requires: 0063-poll_propagate

BEGIN;

CREATE TABLE campaign_type (
    id   SERIAL PRIMARY KEY,
    name TEXT   NOT NULL
);
INSERT INTO campaign_type (name)
    VALUES ('direct message'), ('poll propagation');

CREATE TABLE campaign (
    id         SERIAL PRIMARY KEY,
    type_id    INTEGER REFERENCES campaign_type(id) NOT NULL,
    dm_temp_id INTEGER REFERENCES direct_message(id) NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

INSERT INTO campaign (dm_temp_id, type_id) SELECT id, 1 FROM direct_message;
ALTER TABLE campaign DROP CONSTRAINT campaign_dm_temp_id_fkey;

DROP TABLE direct_message_queue;
ALTER TABLE direct_message DROP CONSTRAINT direct_message_pkey;
ALTER TABLE direct_message ADD COLUMN campaign_id INTEGER REFERENCES campaign(id);

UPDATE direct_message
    SET campaign_id = c.dm_temp_id
    FROM campaign as c
    WHERE direct_message.id = c.dm_temp_id;

ALTER TABLE direct_message ADD PRIMARY KEY (campaign_id), DROP COLUMN id;
ALTER TABLE campaign DROP COLUMN dm_temp_id;

ALTER TABLE poll_propagate ADD COLUMN campaign_id INTEGER REFERENCES campaign(id), DROP CONSTRAINT poll_propagate_pkey, DROP COLUMN id;
ALTER TABLE poll_propagate ADD PRIMARY KEY (campaign_id);

COMMIT;
