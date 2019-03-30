begin;

do $$ begin perform no_plan(); end $$;

set search_path = core, public;

\ir tests/friendships.sql
set local role postgres;
select * from tests.posts_tests();
\ir tests/users.sql

select * from finish();
rollback;
