begin;

select no_plan();

set search_path = core, public;

\echo ============
\echo comments RLS
\echo ============

set local role socnet_anon;

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

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'public cannot see the post'
  );

\echo
\echo When audience=friends of friends
\echo ================================
\echo

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  is_empty(
    $$
    select * from posts where id = 7;
    $$,
    'public cannot see the post'
  );

\echo
\echo When audience=public
\echo =====================
\echo

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  results_eq(
    $$
    select title from posts where id = 3;
    $$,
    $$
    values('Hello everybody')
    $$,
    'public can see the user post'
  );

\echo
\echo When audience=whitelist
\echo =======================
\echo

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'public cannot see the user post'
  );

\echo
\echo When audience=blacklist
\echo =======================
\echo

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'public cannot see the user post'
  );

\echo ================
\echo posts_access rls
\echo ================

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  throws_ok(
    $$
    select * from posts_access;
    $$,
    42501,
    'permission denied for relation posts_access',
    'public cannot see any posts_access'
  );

\echo ===============
\echo friendships rls
\echo ===============

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  throws_ok(
    $$
    select * from friendships;
    $$,
    42501,
    'permission denied for relation friendships',
    'public cannot see any friendships'
  );

\echo ========================
\echo users_details_access rls
\echo ========================

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  throws_ok(
    $$
    select * from users_details_access;
    $$,
    42501,
    'permission denied for relation users_details_access',
    'public cannot see any users_details_access'
  );

\echo =================
\echo users_details rls
\echo =================

\echo
\echo When audience=public
\echo =====================
\echo

set local role socnet_anon;
reset "request.jwt.claim.user_id";

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
