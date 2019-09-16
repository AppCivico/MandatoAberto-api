-- Deploy mandatoaberto:0175-add-notification_bar to pg
-- requires: 0174-drop-questionnaire-constraint

BEGIN;

ALTER TABLE module ADD column part_of_notification_bar BOOLEAN NOT NULL DEFAULT FALSE;
UPDATE module SET part_of_notification_bar = TRUE WHERE name in ('ticket', 'issue');

COMMIT;
