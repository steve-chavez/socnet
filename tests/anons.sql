begin;

select no_plan();

set local search_path = core, public;

set local role socnet_anon;
reset "request.jwt.claim.user_id";

\echo =====
\echo users
\echo =====

select
  results_eq(
    $$
    select count(*) from users;
    $$,
    $$
    values(13::bigint);
    $$,
    'anon can see all users'
  );

\echo =============
\echo users_details
\echo =============

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
    'anon can only see users public details'
  );

\echo ====================
\echo users_details_access
\echo ====================

select
  throws_ok(
    $$
    select * from users_details_access;
    $$,
    42501,
    'permission denied for relation users_details_access',
    'anon cannot see any users_details_access'
  );


\echo ========
\echo comments
\echo ========

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

\echo =====
\echo posts
\echo =====

\echo
\echo when audience=friends
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
\echo when audience=friends of friends
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
\echo when audience=public
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
\echo when audience=whitelist
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
\echo when audience=blacklist
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
\echo when audience=personal
\echo ======================
\echo

select is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'anon cannot see the user post'
  );

\echo ============
\echo posts_access
\echo ============

select
  throws_ok(
    $$
    select * from posts_access;
    $$,
    42501,
    'permission denied for relation posts_access',
    'anon cannot see any posts_access'
  );

\echo ===========
\echo friendships
\echo ===========

select
  throws_ok(
    $$
    select * from friendships;
    $$,
    42501,
    'permission denied for relation friendships',
    'anon cannot see any friendships'
  );

select * from finish();

do $$ begin assert num_failed() = 0; end $$;

rollback;
