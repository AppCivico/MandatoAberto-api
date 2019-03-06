-- Deploy mandatoaberto:0156-add-invite-token to pg
-- requires: 0155-improving-organization-structure

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
ALTER TABLE organization ADD COLUMN invite_token uuid NOT NULL DEFAULT uuid_generate_v4();

COMMIT;
