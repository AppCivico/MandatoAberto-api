-- Deploy mandatoaberto:0126-add-active-bool-on-flows to pg
-- requires: 0125-add-log_action

BEGIN;

ALTER TABLE politician_contact ADD COLUMN active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE answer ADD COLUMN active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE politician ADD COLUMN issue_active BOOLEAN NOT NULL DEFAULT true;

COMMIT;
