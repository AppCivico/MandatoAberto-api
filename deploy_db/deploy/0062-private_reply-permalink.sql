-- Deploy mandatoaberto:0062-private_reply-permalink to pg
-- requires: 0061-private_reply

BEGIN;

ALTER TABLE private_reply ALTER COLUMN permalink DROP NOT NULL;

COMMIT;
