-- Deploy mandatoaberto:0066-user-confirmation to pg
-- requires: 0065-add-politician_id-poll_propagate

BEGIN;

create table user_confirmation (
    id          serial primary key,
    user_id     integer not null references "user"(id),
    token       text not null unique,
    valid_until timestamp without time zone not null, 
    created_at  timestamp without time zone not null default now()
);

alter table "user" add column confirmed boolean not null default 'false';
alter table "user" add column confirmed_at timestamp without time zone ;
update "user" set confirmed = 'true', confirmed_at = now() ;

COMMIT;
