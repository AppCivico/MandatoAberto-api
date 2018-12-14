-- Deploy mandatoaberto:0148-add-unique-module to pg
-- requires: 0147-add-chatbot

BEGIN;

DELETE FROM
    organization_module om1
        USING organization_module om2
WHERE
    om1.id < om2.id
    AND om1.module_id = om2.module_id
    AND om1.organization_id = om2.organization_id;
alter table organization_module ADD CONSTRAINT organization_module_organization_id_module_id_uniq UNIQUE (organization_id, module_id);

COMMIT;
