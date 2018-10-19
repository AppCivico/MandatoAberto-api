-- Deploy mandatoaberto:0133-add-politician_entity_stats to pg
-- requires: 0132-update-campaign

BEGIN;

CREATE TABLE politician_entity_stats (
    politician_entity_id INTEGER REFERENCES politician_entity(id) NOT NULL,
    recipient_id         INTEGER REFERENCES recipient(id),
    entity_is_correct    BOOLEAN NOT NULL,
    created_at           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

COMMIT;
