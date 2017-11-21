-- Deploy mandatoaberto:0018-email_queue to pg
-- requires: 0017-politician-biography

BEGIN;

create table email_queue (
    id serial  primary key,
    body text  not null,
    bcc  text[],
    created_at timestamp without time zone not null default now()
);

COMMIT;
