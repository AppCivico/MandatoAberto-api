-- Deploy mandatoaberto:0069-updating-recipients-page_id to pg
-- requires: 0068-add-recipient-page_id

BEGIN;

UPDATE recipient r SET page_id = ( SELECT fb_page_id FROM politician p WHERE p.user_id = r.politician_id AND fb_page_id IS NOT NULL ) FROM politician p WHERE r.politician_id = p.user_id;


COMMIT;
