-- Deploy mandatoaberto:0145-organization to pg
-- requires: 0144-adding-read-issue

BEGIN;


--- Converting group table
ALTER TABLE "group" ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE "group" me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE "group" ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

--- Converting campaign table
ALTER TABLE campaign ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE campaign me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE campaign ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

DROP TRIGGER IF EXISTS tg_update_campaign_count_summary on public.campaign;

--- Converting recipient table
ALTER TABLE recipient ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE recipient me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE recipient ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

DROP TRIGGER IF EXISTS tg_update_recipient_count_summary on public.recipient;

--- Converting poll table
ALTER TABLE poll ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE poll me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE poll ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

--- Converting issue table
ALTER TABLE issue ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE issue me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE issue ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

--- Converting politician_entity table
ALTER TABLE politician_entity ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE politician_entity me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE politician_entity ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

--- Converting politician_knowledge_base table
ALTER TABLE politician_knowledge_base ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE politician_knowledge_base me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE politician_knowledge_base ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

--- Converting politician_contact table
ALTER TABLE politician_contact ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE politician_contact me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE politician_contact ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

--- Converting politician_greeting table
ALTER TABLE politician_greeting ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE politician_greeting me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE politician_greeting ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

--- Converting private_reply table
ALTER TABLE private_reply ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id);
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
UPDATE private_reply me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE private_reply ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

--- Converting politician_private_reply_config table
ALTER TABLE politician_private_reply_config ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id) UNIQUE;
WITH politician AS (
    SELECT
        u.id  AS id,
        oc.id AS organization_chatbot_id
    FROM
        politician p,
        "user" u,
        organization o,
        organization_chatbot oc,
        politician_private_reply_config pc
    WHERE p.user_id = u.id
    AND u.organization_id = o.id
    AND o.id = oc.organization_id
    AND p.user_id = pc.politician_id
    AND p.user_id NOT IN (SELECT politician_id FROM politician_private_reply_config)
)
UPDATE politician_private_reply_config me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE politician_private_reply_config ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

--- Converting politician_private_reply_config table
ALTER TABLE poll_self_propagation_config ADD COLUMN organization_chatbot_id INTEGER REFERENCES organization_chatbot(id) UNIQUE;
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
UPDATE poll_self_propagation_config me SET organization_chatbot_id = politician.organization_chatbot_id FROM politician WHERE me.politician_id = politician.id;
ALTER TABLE poll_self_propagation_config ALTER COLUMN organization_chatbot_id SET NOT NULL, DROP COLUMN politician_id;

DROP TRIGGER IF EXISTS tg_add_politician_configs_and_summary on public.user;

CREATE OR REPLACE FUNCTION public.f_tg_add_organization_chatbot_configs_and_summary()
  RETURNS trigger AS
$BODY$
BEGIN

    INSERT INTO politician_private_reply_config (organization_chatbot_id) VALUES (NEW.id);
    INSERT INTO poll_self_propagation_config (organization_chatbot_id) VALUES (NEW.id);

    RETURN NULL;
END;
$BODY$
    LANGUAGE plpgsql;

CREATE TRIGGER tg_add_organization_chatbot_configs
    AFTER INSERT
    ON public.organization_chatbot
    FOR EACH ROW
    EXECUTE PROCEDURE public.f_tg_add_organization_chatbot_configs_and_summary();

COMMIT;
