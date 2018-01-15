-- Deploy mandatoaberto:0048-relations-names to pg
-- requires: 0047-rename-citizen-to-recipient

BEGIN;

ALTER TABLE question_options RENAME TO poll_question_option;
ALTER TABLE poll_questions RENAME TO poll_question;
ALTER TABLE poll_question_option RENAME question_id TO poll_question_id;
ALTER TABLE answers RENAME TO answer;
ALTER TABLE poll_results RENAME TO poll_result;
ALTER TABLE poll_result RENAME option_id TO poll_question_option_id;

COMMIT;
