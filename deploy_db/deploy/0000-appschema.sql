-- Deploy mandatoaberto:0000-appschema to pg

BEGIN;

CREATE TABLE "user"
(
  id         SERIAL PRIMARY KEY,
  email      text not null unique,
  password   text not null,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE role (
    id   INTEGER PRIMARY KEY,
    name TEXT
);

INSERT INTO role VALUES (1, 'admin');
INSERT INTO role VALUES (2, 'user');

CREATE TABLE user_role (
    user_id integer references "user"(id),
    role_id integer references role(id),
    CONSTRAINT user_role_pkey PRIMARY KEY (user_id, role_id)
);

INSERT INTO "user" (password, email) VALUES ('$2y$10$O4iFv47vPptdx1NdDWXjn.8DQeP.XMSui.e7m3ex391.rNoIYbIgu', 'lucas.ansei@eokoe.com');
INSERT INTO user_role (role_id, user_id) VALUES (1, 1);

COMMIT;
