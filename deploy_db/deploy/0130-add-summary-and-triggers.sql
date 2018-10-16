-- Deploy mandatoaberto:0130-add-summary-and-triggers to pg
-- requires: 0129-updating-logs

BEGIN;

-- Creating politician_summary table
ALTER TABLE campaign ALTER COLUMN politician_id SET NOT NULL;

CREATE TABLE politician_summary (
    politician_id      INTEGER UNIQUE PRIMARY KEY REFERENCES politician(user_id),
    has_active_chatbot BOOLEAN NOT NULL DEFAULT false,
    recipient_count    INTEGER NOT NULL DEFAULT 0,
    campaign_count     INTEGER NOT NULL DEFAULT 0
);

INSERT INTO politician_summary (politician_id, has_active_chatbot, recipient_count, campaign_count)
    SELECT
        p.user_id AS politician_id,
        ( CASE WHEN p.fb_page_access_token IS NOT NULL THEN true ELSE false END ) AS has_active_chatbot,
        ( CASE WHEN r.count > 0 THEN r.count ELSE 0 END ) AS recipient_count,
        ( CASE WHEN c.count > 0 THEN c.count ELSE 0 END ) AS campaign_count
    FROM
        politician AS p
    FULL OUTER JOIN (
        SELECT
            politician_id,
            count(1) AS count
        FROM recipient
        GROUP BY politician_id
    ) AS r ON (p.user_id = r.politician_id)
    FULL OUTER JOIN (
        SELECT
            politician_id,
            count(1) AS count
        FROM campaign
        GROUP BY politician_id
    ) AS c ON (p.user_id = c.politician_id)
    GROUP BY p.user_id, r.count, c.count;

-- Creating metrics view
CREATE SCHEMA metrics;

CREATE OR REPLACE VIEW metrics.general AS
    SELECT
        p.user_id AS id,
        u.email,
        u.approved,
        p.name,
        p.gender,
        p.premium,
        s.recipient_count,
        s.campaign_count,
        s.has_active_chatbot
    FROM
        politician AS p
    JOIN
        politician_summary AS s ON ( p.user_id = s.politician_id )
    JOIN
        "user" AS u ON ( p.user_id = u.id );

-- Creating functions for triggers
CREATE OR REPLACE FUNCTION public.f_tg_add_politician_configs_and_summary()
  RETURNS trigger AS
$BODY$
BEGIN

    IF NEW.approved = true AND OLD.approved = false THEN

        INSERT INTO politician_summary (politician_id) VALUES (NEW.id);
        INSERT INTO politician_private_reply_config (politician_id) VALUES (NEW.id);
        INSERT INTO poll_self_propagation_config (politician_id) VALUES (NEW.id);

    END IF;

    RETURN NULL;
END;
$BODY$
    LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.f_tg_update_summary_recipient_count()
    RETURNS TRIGGER AS
$BODY$
BEGIN

    UPDATE politician_summary SET recipient_count = recipient_count + 1 WHERE politician_id = NEW.politician_id;

    RETURN NULL;

END;
$BODY$
    LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.f_tg_update_summary_campaign_count()
    RETURNS TRIGGER AS
$BODY$
BEGIN

    UPDATE politician_summary SET campaign_count = campaign_count + 1 WHERE politician_id = NEW.politician_id;

    RETURN NULL;

END;
$BODY$
    LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.f_tg_update_active_chatbot_summary()
    RETURNS TRIGGER AS
$BODY$
BEGIN

    IF NEW.fb_page_access_token IS NOT NULL THEN
        UPDATE politician_summary SET has_active_chatbot = true WHERE politician_id = NEW.user_id;
    ELSE
        UPDATE politician_summary SET has_active_chatbot = false WHERE politician_id = NEW.user_id;
    END IF;

    RETURN NULL;

END;
$BODY$
    LANGUAGE plpgsql;

-- Creating triggers
CREATE TRIGGER tg_add_politician_configs_and_summary
    AFTER UPDATE
    ON public.user
    FOR EACH ROW
    EXECUTE PROCEDURE public.f_tg_add_politician_configs_and_summary();

CREATE TRIGGER tg_update_recipient_count_summary
    AFTER INSERT
    ON public.recipient
    FOR EACH ROW
    EXECUTE PROCEDURE public.f_tg_update_summary_recipient_count();

CREATE TRIGGER tg_update_campaign_count_summary
    AFTER INSERT
    ON public.campaign
    FOR EACH ROW
    EXECUTE PROCEDURE public.f_tg_update_summary_campaign_count();

CREATE TRIGGER tg_update_active_chatbot_summary
    AFTER UPDATE
    ON public.politician
    FOR EACH ROW
    EXECUTE PROCEDURE public.f_tg_update_active_chatbot_summary();

COMMIT;
