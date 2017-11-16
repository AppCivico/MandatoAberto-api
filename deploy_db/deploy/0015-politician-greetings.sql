-- Deploy mandatoaberto:0015-politician-greetings to pg
-- requires: 0014-poll_name

BEGIN;

CREATE TABLE politician_greetings(
	id SERIAL PRIMARY KEY,
    politician_id integer NOT NULL,
  	text text NOT NULL,
 	CONSTRAINT politician_greetings_politician_id_fkey FOREIGN KEY (politician_id)
    REFERENCES public.politician (user_id) MATCH SIMPLE
    ON UPDATE NO ACTION ON DELETE NO ACTION
);

COMMIT;
