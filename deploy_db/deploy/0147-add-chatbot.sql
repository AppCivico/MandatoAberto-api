-- Deploy mandatoaberto:0147-add-chatbot to pg
-- requires: 0146-add-permission-and-modules

BEGIN;

ALTER TABLE organization_chatbot ALTER COLUMN chatbot_platform_id SET DEFAULT 1;

INSERT INTO organization_chatbot (organization_id) select organization_id from "user" u, user_organization uo  WHERE u.id = uo.user_id and NOT EXISTS ( SELECT 1 FROM organization_chatbot WHERE organization_id  = uo.organization_id);


COMMIT;
