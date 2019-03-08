-- Deploy mandatoaberto:0151-create-view to pg
-- requires: 0150-add-dialogflow-config

BEGIN;

CREATE OR REPLACE VIEW public.user_with_organization_data AS
    SELECT
        u.id    AS user_id,
        u.email AS email,
        o.id    AS organization_id,
        c.id    AS chatbot_id
    FROM
        "user" u
    JOIN
        user_organization AS uo ON ( u.id = uo.user_id )
    JOIN
        organization AS o ON ( o.id = uo.organization_id )
    JOIN
        organization_chatbot AS c ON ( c.organization_id = o.id )
    ORDER BY u.id;

COMMIT;
