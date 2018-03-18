-- Deploy mandatoaberto:0068-add-recipient-page_id to pg
-- requires: 0067-add-instagram-politician_contact

BEGIN;

ALTER TABLE recipient ADD COLUMN page_id TEXT;
UPDATE recipient r SET page_id =
    ( SELECT fb_page_id FROM politician p WHERE p.user_id = r.politician_id )
    WHERE name = ( SELECT name FROM recipient ORDER BY name LIMIT 1 );
UPDATE recipient SET page_id = '' WHERE page_id IS NULL;
ALTER TABLE recipient ALTER COLUMN page_id SET NOT NULL;

COMMIT;
