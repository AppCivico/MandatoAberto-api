-- Deploy mandatoaberto:0128-add-adaptive-chunking to pg
-- requires: 0127-add-log_action

BEGIN;

SELECT * FROM set_adaptive_chunking('logs', 'estimate');

COMMIT;
