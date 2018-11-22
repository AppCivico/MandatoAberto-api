-- Deploy mandatoaberto:0137-add-organization to pg
-- requires: 0136-allow-null-party-and-office

BEGIN;


--- Creating table to support organizations
CREATE TABLE organization (
    id                 SERIAL PRIMARY KEY,
    name               TEXT   NOT NULL,
    premium            BOOLEAN NOT NULL DEFAULT false,
    premium_updated_at TIMESTAMP WITHOUT TIME ZONE,
    approved           BOOLEAN NOT NULL DEFAULT false,
    approved_at        TIMESTAMP WITHOUT TIME ZONE,
    updated_at         TIMESTAMP WITHOUT TIME ZONE,
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

--- Altering "user" table so it can support the "politician" table merge and the organization structure
ALTER TABLE "user" ADD COLUMN organization_id INTEGER REFERENCES organization(id);
ALTER TABLE "user" ADD COLUMN party_id INTEGER REFERENCES party(id);
ALTER TABLE "user" ADD COLUMN office_id INTEGER REFERENCES office(id);
ALTER TABLE "user" ADD COLUMN gender TEXT;
ALTER TABLE "user" ADD COLUMN movement_id INTEGER REFERENCES movement(id);
ALTER TABLE "user" ADD COLUMN address_state_id INTEGER REFERENCES state(id);
ALTER TABLE "user" ADD COLUMN address_city_id INTEGER REFERENCES city(id);
ALTER TABLE "user" ADD COLUMN name TEXT;

--- Updating "user" data
UPDATE
    "user" me
SET
    party_id = p.party_id,
    office_id = p.office_id,
    gender = p.gender,
    movement_id = p.movement_id,
    address_state_id = p.address_state_id,
    address_city_id = p.address_city_id,
    name = p.name
FROM
    politician p
WHERE
    me.id = p.user_id;

--- Inserting organization rows
INSERT INTO organization (name, premium, premium_updated_at, approved, approved_at)
SELECT p.name, premium, premium_updated_at, approved, approved_at FROM politician p, "user" u WHERE u.id = p.user_id;

--- Setting the organization_id
UPDATE "user" u SET organization_id = o.id FROM organization o WHERE u.name = o.name;

---ALTER TABLE "user" ALTER COLUMN organization_id SET NOT NULL;
---ALTER TABLE "user" ALTER COLUMN name SET NOT NULL;
---ALTER TABLE "user" ALTER COLUMN address_city_id SET NOT NULL;
---ALTER TABLE "user" ALTER COLUMN address_state_id SET NOT NULL;

--- Creating table of available chatbot plaforms, ie: Facebook, Twitter
CREATE TABLE chatbot_platform (
    id         INTEGER PRIMARY KEY,
    name       TEXT NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);
INSERT INTO chatbot_platform ( id, name ) VALUES (1, 'facebook'), (2, 'twitter');

--- Creating table of organization chatbots
CREATE TABLE organization_chatbot (
    id                  SERIAL PRIMARY KEY,
    chatbot_platform_id INTEGER NOT NULL REFERENCES chatbot_platform(id),
    organization_id     INTEGER NOT NULL REFERENCES organization(id),
    created_at          TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

--
--- (new) Chatbot config tables
--

CREATE TABLE organization_chatbot_general_config(
    id                      SERIAL PRIMARY KEY,
    organization_chatbot_id INTEGER REFERENCES organization_chatbot(id) NOT NULL UNIQUE,
    is_active               BOOLEAN NOT NULL DEFAULT true,
    issue_active            BOOLEAN NOT NULL DEFAULT true,
    use_dialogflow          BOOLEAN NOT NULL DEFAULT true,
    share_url               TEXT,
    share_text              TEXT,
    updated_at              TIMESTAMP WITHOUT TIME ZONE,
    created_at              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE organization_chatbot_facebook_config (
    id                      SERIAL PRIMARY KEY,
    organization_chatbot_id INTEGER REFERENCES organization_chatbot(id) NOT NULL UNIQUE,
    access_token            TEXT NOT NULL,
    page_id                 TEXT NOT NULL,
    updated_at              TIMESTAMP WITHOUT TIME ZONE,
    created_at              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE organization_chatbot_twitter_config (
    id                      SERIAL PRIMARY KEY,
    organization_chatbot_id INTEGER REFERENCES organization_chatbot(id) NOT NULL UNIQUE,
    twitter_id              TEXT NOT NULL,
    oauth_token             TEXT NOT NULL,
    token_secret            TEXT NOT NULL,
    updated_at              TIMESTAMP WITHOUT TIME ZONE,
    created_at              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

--
--- (new) Chatbot config tables
--

--- Inserting data on the chatbot config tables
INSERT INTO organization_chatbot (chatbot_platform_id, organization_id)
SELECT id, 1 as chatbot_platform_id FROM organization;

WITH cte AS (
    SELECT
        oc.id AS organization_chatbot_id,
        true AS is_active,
        issue_active,
        use_dialogflow,
        share_url,
        share_text
    FROM
        politician p,
        "user" u,
        organization o,
        organization_chatbot oc
    WHERE u.id = p.user_id
    AND u.organization_id = o.id
    AND oc.organization_id = o.id
    AND p.fb_page_access_token IS NOT NULL
)
INSERT INTO organization_chatbot_general_config (organization_chatbot_id, is_active, issue_active, use_dialogflow, share_url, share_text)
SELECT * FROM cte;

WITH cte AS (
    SELECT
        oc.id AS organization_chatbot_id,
        p.fb_page_access_token AS access_token,
        p.fb_page_id AS page_id
    FROM
        politician p,
        "user" u,
        organization o,
        organization_chatbot oc
    WHERE u.id = p.user_id
    AND u.organization_id = o.id
    AND oc.organization_id = o.id
    AND p.fb_page_access_token IS NOT NULL
)
INSERT INTO organization_chatbot_facebook_config (organization_chatbot_id, access_token, page_id)
SELECT * FROM cte;

--- Alter summary table
ALTER TABLE politician_summary ADD COLUMN user_id INTEGER REFERENCES "user"(id);
UPDATE politician_summary SET user_id = politician_id;

COMMIT;
