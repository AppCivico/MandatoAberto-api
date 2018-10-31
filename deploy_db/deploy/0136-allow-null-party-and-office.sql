-- Deploy mandatoaberto:0136-allow-null-party-and-office to pg
-- requires: 0135-add-err_reason

BEGIN;

ALTER TABLE politician ALTER COLUMN office_id DROP NOT NULL;
ALTER TABLE politician ALTER COLUMN party_id DROP NOT NULL;

COMMIT;
