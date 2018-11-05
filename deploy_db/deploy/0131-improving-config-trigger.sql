-- Deploy mandatoaberto:0131-improving-config-trigger to pg
-- requires: 0130-add-summary-and-triggers

BEGIN;

DROP TRIGGER IF EXISTS tg_add_politician_configs_and_summary on public.user;
CREATE TRIGGER tg_add_politician_configs_and_summary
    AFTER UPDATE OF approved ON public.user
    FOR EACH ROW
    EXECUTE PROCEDURE public.f_tg_add_politician_configs_and_summary();

COMMIT;
