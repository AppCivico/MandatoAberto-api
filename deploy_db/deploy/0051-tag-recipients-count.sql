-- Deploy mandatoaberto:0051-tag-recipients-count to pg
-- requires: 0050-tag-hstore

BEGIN;

ALTER TABLE tag DROP COLUMN calc ;
ALTER TABLE tag ADD COLUMN recipients_count INTEGER ;
ALTER TABLE tag ADD COLUMN status TEXT CHECK(status::text = ANY(ARRAY['ready', 'processing'])) NOT NULL DEFAULT 'processing' ;
ALTER TABLE tag RENAME COLUMN last_calc_at TO last_recipients_calc_at ;

COMMIT;
