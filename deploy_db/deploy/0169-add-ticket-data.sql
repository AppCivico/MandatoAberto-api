-- Deploy mandatoaberto:0169-add-ticket-data to pg
-- requires: 0168-add-ticket_log

BEGIN;

CREATE TABLE ticket_log_action (
    id   INTEGER PRIMARY KEY,
    code TEXT NOT NULL UNIQUE
);
INSERT INTO ticket_log_action (id, code) VALUES (1, 'ticket criado'), (2, 'ticket designado'), (3, 'ticket movido'), (4, 'ticket cancelado');
ALTER TABLE ticket_log ADD COLUMN action_id INTEGER NOT NULL REFERENCES ticket_log_action(id);
ALTER TABLE ticket_log ADD COLUMN data JSON NOT NULL DEFAULT '{}';
ALTER TABLE ticket DROP CONSTRAINT ticket_status_check;
ALTER TABLE ticket ADD CONSTRAINT ticket_status_check CHECK (status = 'pending'::text OR status = 'closed'::text OR status = 'progress'::text OR status = 'canceled'::text);
ALTER TABLE ticket ADD COLUMN data JSON NOT NULL DEFAULT '{}';

COMMIT;
