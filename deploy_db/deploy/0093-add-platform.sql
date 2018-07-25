-- Deploy mandatoaberto:0093-add-platform to pg
-- requires: 0092-drop-notnull-origin_dialog

BEGIN;

ALTER TABLE recipient ADD COLUMN platform TEXT;
UPDATE recipient SET platform = 'facebook' WHERE fb_id IS NOT NULL;
UPDATE recipient SET platform = 'twitter'  WHERE twitter_id IS NOT NULL;
UPDATE recipient SET platform = 'faceook'  WHERE platform IS NULL;
ALTER TABLE recipient ALTER COLUMN platform SET NOT NULL;

COMMIT;
