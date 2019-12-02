-- Deploy mandatoaberto:0187-add-ticket-response-interval to pg
-- requires: 0186-add-fb_app_id

BEGIN;

ALTER TABLE organization_ticket_type ADD COLUMN usual_response_interval INTERVAL;

COMMIT;
