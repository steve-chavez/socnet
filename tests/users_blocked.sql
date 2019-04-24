begin;
select no_plan();

set search_path = core, public;

\echo =========
\echo users rls
\echo =========

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from users where id in (3, 6);
    $$,
    'blockee cannot see the users that blocked him'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

select
  results_eq(
    $$
    select username from users where id = 5;
    $$,
    $$
    values('yoko')
    $$,
    'blocker can see blocked users'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 6;

select
  results_eq(
    $$
    select username from users where id = 5;
    $$,
    $$
    values('yoko')
    $$,
    'blocker can see blocked users'
  );

\echo ========================
\echo users_details_access rls
\echo ========================

set local role socnet_user;
set local "request.jwt.claim.user_id" to 11;

select
  is_empty(
    $$
    select * from users_details_access where users_details_id = 13 and 11 in (source_user_id, target_user_id);
    $$,
    'blockee cannot see users_details_access from a blocker'
  );

\echo =================
\echo users_details rls
\echo =================

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select email, phone from users_details where user_id = 6;
    $$,
    'blocked user cannot see the public users_details of a blocker'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 11;

select
  is_empty(
    $$
    select email, phone from users_details where user_id = 13;
    $$,
    'friends of friends which are blocked cannot see the users details'
  );

\echo =========
\echo posts rls
\echo =========

set local role socnet_user;
set local "request.jwt.claim.user_id" to 11;

select
  is_empty(
    $$
    select title from posts where id = 9;
    $$,
    'blocked friends of friends cannot see the post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select title from posts where id = 8;
    $$,
    'blocked user cannot see the public post of a blocker'
  );

\echo
\echo ================
\echo posts_access rls
\echo ================

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select from posts_access where post_id = 6 and 5 in (source_user_id, target_user_id)
    $$,
    'blockee cannot see posts_access from a blocker'
  );

\echo ============
\echo comments rls
\echo ============

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from comments where user_id = 3;
    $$,
    'a blockee cannot see the comments of a blocker, even if the post is public'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

select
  results_eq(
    $$
    select count(*) from comments where user_id = 5;
    $$,
    $$
    values(1::bigint)
    $$,
    'a blocker can see the blockee comments'
  );

\echo ===============
\echo friendships rls
\echo ===============

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from friendships where source_user_id in (3, 6) and target_user_id = 5
    $$,
    'the blockee cannot see blocked friendships'
  );

select
  is_empty(
    $$
    update friendships set status = 'accepted' where status = 'blocked' returning *
    $$,
    'the blockee cannot modify blocked friendships'
  );

select
  is_empty(
    $$
    delete from friendships where source_user_id in (6,3) and target_user_id = 5 returning *;
    $$,
    'the blockee cannot delete blocked friendships'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 6;

select
  results_eq(
    $$
    update friendships
    set status = 'accepted'
    where
      6 in (source_user_id, target_user_id) and
      status = 'blocked' and blockee_id = 5
    returning 1
    $$,
    $$
    values(1)
    $$,
    'the blocker can update blocked status'
  );

select
  results_eq(
    $$
    select blockee_id from friendships
    where source_user_id = 6 and target_user_id = 5
    $$,
    $$
    values(null::integer)
    $$,
    'the blockee_id was set to null'
  );

select * from finish();

do $$ begin assert num_failed() = 0; end $$;

rollback;
