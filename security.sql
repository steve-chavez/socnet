drop role if exists socnet_anon;
create role socnet_anon;

drop role if exists socnet_user;
create role socnet_user;

grant usage
on schema core
to
  socnet_user
, socnet_anon;

alter table  users                 enable row level security;
alter table  users_details         enable row level security;
alter table  users_details_access  enable row level security;
alter table  friendships           enable row level security;
alter table  posts_access          enable row level security;
alter table  posts                 enable row level security;
alter table  comments              enable row level security;

\ir security/anons.sql
\ir security/comments.sql
\ir security/friendships.sql
\ir security/posts.sql
\ir security/users.sql
\ir security/users_blocked.sql
