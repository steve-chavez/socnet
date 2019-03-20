begin;

do $$ begin perform no_plan(); end $$;

set search_path = core, public;

\ir tests/friendships.sql
\ir tests/posts.sql
\ir tests/users.sql

select * from finish();
rollback;
