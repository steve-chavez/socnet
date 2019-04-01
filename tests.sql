\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true

drop schema if exists tests cascade;
create schema tests;

set search_path = tests, core, public;

\ir tests/friendships.sql
\ir tests/posts.sql
\ir tests/users.sql

-- with runtests each function will run in its own transaction
-- also no_plan() and finish() calls are not needed
select * from runtests('tests', 'tests$');
