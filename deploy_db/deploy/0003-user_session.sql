-- Deploy mandatoaberto:0003-user_session to pg
-- requires: 0002-state-and-city

BEGIN;

CREATE TABLE user_session
(
  id           serial primary key,
  user_id      integer not null references "user"(id),
  api_key      text not null unique,
  created_at   timestamp without time zone not null default now(),
  valid_until  timestamp without time zone not null
);

COMMIT;
