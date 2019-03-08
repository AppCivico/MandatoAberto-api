-- Deploy mandatoaberto:0152-add-constraint to pg
-- requires: 0151-create-view

BEGIN;

WITH duplicate_intents AS (
    SELECT
        count(1) AS count,
        organization_chatbot_id,
        name
    FROM
        politician_entity
    GROUP BY
        organization_chatbot_id,
        name
), intents AS (
    SELECT
        e.id,
        e.organization_chatbot_id,
        e.name
    FROM
        politician_entity e,
        duplicate_intents d
    WHERE
        e.organization_chatbot_id = d.organization_chatbot_id
        AND e.name = d.name
        AND d.count > 1
    GROUP BY e.id
    ORDER BY organization_chatbot_id
), intents_with_kb AS (
    SELECT
        i.id
    FROM
        intents i,
        politician_knowledge_base kb
    WHERE i.id = any(kb.entities)
), ids_to_delete AS (
    SELECT
        i.id
    FROM
        intents i,
        intents_with_kb ikb
    WHERE
        i.id NOT IN ( SELECT id FROM intents_with_kb )
    GROUP BY i.id
)
DELETE FROM politician_entity e USING ids_to_delete d WHERE e.id = d.id;


ALTER TABLE politician_entity ADD CONSTRAINT chatbot_id_name UNIQUE (organization_chatbot_id, name);


COMMIT;
