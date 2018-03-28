-- Deploy mandatoaberto:0074-adding-admin-timestamps-and-ids to pg
-- requires: 0073-updating-greetings-texts

BEGIN;

ALTER TABLE "user" ADD COLUMN approved_by_admin_id INTEGER REFERENCES "user"(id);

ALTER TABLE dialog
    ADD COLUMN created_at          TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    ADD COLUMN created_by_admin_id INTEGER REFERENCES "user"(id),
    ADD COLUMN updated_at          TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    ADD COLUMN updated_by_admin_id INTEGER REFERENCES "user"(id);

ALTER TABLE question
    ADD COLUMN created_at          TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    ADD COLUMN created_by_admin_id INTEGER REFERENCES "user"(id),
    ADD COLUMN updated_at          TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    ADD COLUMN updated_by_admin_id INTEGER REFERENCES "user"(id);

UPDATE dialog SET created_by_admin_id = 1;
ALTER TABLE dialog ALTER COLUMN created_by_admin_id SET NOT NULL;

UPDATE question SET created_by_admin_id = 1;
ALTER TABLE dialog ALTER COLUMN created_by_admin_id SET NOT NULL;

COMMIT;
