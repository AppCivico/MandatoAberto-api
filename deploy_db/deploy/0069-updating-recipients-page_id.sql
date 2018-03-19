-- Deploy mandatoaberto:0069-updating-recipients-page_id to pg
-- requires: 0068-add-recipient-page_id

BEGIN;

UPDATE recipient AS r SET page_id = p.page_id FROM
    ( SELECT page_id, user_id
        FROM politician AS p,
             recipient AS r
        WHERE p.user_id = r.politician_id
    ) AS p
    WHERE p.user_id = r.user_id;

COMMIT;
