-- Deploy mandatoaberto:0174-drop-questionnaire-constraint to pg
-- requires: 0173-add-module-resultset_class

BEGIN;

ALTER TABLE questionnaire_question DROP CONSTRAINT questionnaire_question_code_key;
ALTER TABLE questionnaire_question ADD CONSTRAINT questionnaire_question_code_map_key UNIQUE (questionnaire_map_id, code);

COMMIT;
