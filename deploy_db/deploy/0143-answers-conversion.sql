-- Deploy mandatoaberto:0143-answers-conversion to pg
-- requires: 0142-add-project_id

BEGIN;

DELETE FROM user_role WHERE user_id IN ( SELECT id FROM "user" WHERE organization_id IS NULL AND id != 1 );
DELETE FROM user_session WHERE user_id IN ( SELECT id FROM "user" WHERE organization_id IS NULL AND id != 1 );
DELETE FROM "user" WHERE id IN ( SELECT id FROM "user" WHERE organization_id IS NULL AND id != 1 );


--- Converting answer table
ALTER TABLE answer ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
WITH politician AS (
    SELECT
        u.id  AS id,
        oc.id AS organization_chatbot_id
    FROM
        politician p,
        "user" u,
        organization o,
        organization_chatbot oc
    WHERE p.user_id = u.id
    AND u.organization_id = o.id
    AND o.id = oc.organization_id
)
UPDATE answer me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE answer ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

COMMIT;
