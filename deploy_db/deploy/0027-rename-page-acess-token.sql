-- Deploy mandatoaberto:0027-rename-page-acess-token to pg
-- requires: 0026-removing-politicianid-dmqueue

BEGIN;

ALTER TABLE politician RENAME COLUMN fb_page_acess_token TO fb_page_access_token;

COMMIT;
