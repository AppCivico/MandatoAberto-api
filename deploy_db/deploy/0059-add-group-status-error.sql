-- Deploy mandatoaberto:0059-add-group-status-error to pg
-- requires: 0058-blacklist-facebook-messenger

BEGIN;

ALTER TABLE "group" DROP CONSTRAINT tag_status_check;
ALTER TABLE "group" ADD CONSTRAINT tag_status_check CHECK (status = ANY(ARRAY['ready'::text, 'processing'::text, 'error'::text ]));

COMMIT;
