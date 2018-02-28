-- Deploy mandatoaberto:0021-drop-politician-biography to pg
-- requires: 0020-question-citizen-input

BEGIN;

DROP TABLE politician_biography;

COMMIT;
