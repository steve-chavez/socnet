begin;

select no_plan();

set local search_path = core, public;

set local role socnet_anon;
reset "request.jwt.claim.user_id";

\echo ============
\echo comments RLS
\echo ============

select
  results_eq(
    $$
    select count(*) from comments where post_id = 3;
    $$,
    $$
    values(3::bigint)
    $$,
    'anon can see the comments of a public post'
  );

\echo =========
\echo posts RLS
\echo =========

\echo
\echo When audience=friends
\echo =====================
\echo

select
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'anon cannot see the post'
  );

\echo
\echo When audience=friends of friends
\echo ================================
\echo

select
  is_empty(
    $$
    select * from posts where id = 7;
    $$,
    'anon cannot see the post'
  );

\echo
\echo When audience=public
\echo =====================
\echo

select
  results_eq(
    $$
    select title from posts where id = 3;
    $$,
    $$
    values('Hello everybody')
    $$,
    'anon can see the user post'
  );

\echo
\echo When audience=whitelist
\echo =======================
\echo

select
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'anon cannot see the user post'
  );

\echo
\echo When audience=blacklist
\echo =======================
\echo

select
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'anon cannot see the user post'
  );

\echo
\echo When audience=personal
\echo ======================
\echo

select is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'anon cannot see the user post'
  );

\echo ================
\echo posts_access rls
\echo ================

select
  throws_ok(
    $$
    select * from posts_access;
    $$,
    42501,
    'permission denied for relation posts_access',
    'anon cannot see any posts_access'
  );

\echo ===============
\echo friendships rls
\echo ===============

select
  throws_ok(
    $$
    select * from friendships;
    $$,
    42501,
    'permission denied for relation friendships',
    'anon cannot see any friendships'
  );

\echo ========================
\echo users_details_access rls
\echo ========================

select
  throws_ok(
    $$
    select * from users_details_access;
    $$,
    42501,
    'permission denied for relation users_details_access',
    'anon cannot see any users_details_access'
  );

\echo =================
\echo users_details rls
\echo =================

\echo
\echo When audience=public
\echo =====================
\echo

select
  results_eq(
    $$
    select email from users_details;
    $$,
    $$
    values
      ('ringo@thebeatles.fake'::citext),
      ('brian@thebeatles.fake'::citext)
    $$,
    'anon can only see public users details'
  );

select * from finish();

do $$ begin assert num_failed() = 0; end $$;

rollback;
