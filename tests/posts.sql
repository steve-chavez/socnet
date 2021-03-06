begin;

select no_plan();

set search_path = core, public;

set local role socnet_user;

\echo ========================
\echo posts_access constraints
\echo ========================

set local "request.jwt.claim.user_id" to 3;

select
  throws_ok(
    $$
    insert into posts_access(post_id, creator_id, source_user_id, target_user_id, access_type) values (5, 3, 3, 4, 'whitelist');
    insert into posts_access(post_id, creator_id, source_user_id, target_user_id, access_type) values (5, 3, 3, 4, 'whitelist');
    $$,
    'duplicate key value violates unique constraint "posts_access_pkey"',
    'There can only be one post whitelist entry for a friend'
  );

select
  throws_ok(
    $$
    insert into posts_access(post_id, creator_id, source_user_id, target_user_id, access_type) values (5, 3, 2, 3, 'blacklist');
    insert into posts_access(post_id, creator_id, source_user_id, target_user_id, access_type) values (5, 3, 2, 3, 'blacklist');
    $$,
    'duplicate key value violates unique constraint "posts_access_pkey"',
    'There can only be one post blacklist entry for a friend'
  );

\echo ================
\echo posts_access rls
\echo ================

set local "request.jwt.claim.user_id" to 2;

select
  results_eq(
    $$
    select post_id from posts_access;
    $$,
    $$
    values(4)
    $$,
    'an user can only see posts_access which he is a part of'
  );

set local "request.jwt.claim.user_id" to 2;

select
  throws_ok(
    $$
    insert into posts_access values (6, 6, 2, 6,'whitelist');
    $$,
    42501,
    'new row violates row-level security policy for table "posts_access"',
    'an user cannot include himself in the whitelist of a post he does not own'
  );

select
  throws_ok(
    $$
    insert into posts_access values (6, 6, 3, 6,'whitelist');
    $$,
    42501,
    'new row violates row-level security policy for table "posts_access"',
    'an user cannot include others on a whitelist of a post he does not own'
  );

set local "request.jwt.claim.user_id" to 6;

select
  lives_ok(
    $$
    insert into posts_access values (6, 6, 2, 6,'whitelist');
    $$,
    'post owner can include friends in the post whitelist'
  );

select
  throws_ok(
    $$
    insert into posts_access values (6, 6, 4, 6,'whitelist');
    $$,
    23503,
    'insert or update on table "posts_access" violates foreign key constraint "posts_access_source_user_id_fkey"',
    'post owner cannot include non-friends in the post whitelist'
  );

set local "request.jwt.claim.user_id" to 1;

select
  is_empty(
    $$
    delete from posts_access where post_id = 5 and 1 in (source_user_id, target_user_id) returning 1;
    $$,
    'blacklisted user cannot delete himself from the blacklist'
  );

\echo =========
\echo posts RLS
\echo =========

set local "request.jwt.claim.user_id" to 1;

select
  throws_ok(
    $$
    insert into posts(creator_id, title, body)
    values (6, 'Not my post', 'Just a test');
    $$,
    42501,
    'new row violates row-level security policy for table "posts"',
    'An user cannot create a post in the name of another user'
  );

set local "request.jwt.claim.user_id" to 6;

select
  lives_ok(
    $$
    insert into posts(creator_id, title, body)
    values (6, 'My post', 'Just a test');
    $$,
    'Post owner can create a post in its name successfully'
  );

set local "request.jwt.claim.user_id" to 6;

select
  is_empty(
    $$
    delete from posts where id in (3, 7) returning 1;
    $$,
    'user cannot delete posts that belong to other users'
  );

\echo
\echo when audience=friends
\echo =====================
\echo

set local "request.jwt.claim.user_id" to 1;

select
  results_eq(
    $$
    select title from posts where id = 1;
    $$,
    $$
    values('Excluding Yoko')
    $$,
    'the creator can see its post'
  );

set local "request.jwt.claim.user_id" to 2;

select
  results_eq(
    $$
    select title from posts where id = 1;
    $$,
    $$
    values('Excluding Yoko')
    $$,
    'friends can see the post'
  );

set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'non-friends cannot see the post'
  );

\echo
\echo when audience=friends of friends
\echo ================================
\echo

set local "request.jwt.claim.user_id" to 5;

select
  results_eq(
    $$
    select title from posts where id = 7;
    $$,
    $$
    values('Hey!')
    $$,
    'friends of friends can see the post'
  );

set local "request.jwt.claim.user_id" to 2;

select
  results_eq(
    $$
    select title from posts where id = 7;
    $$,
    $$
    values('Hey!')
    $$,
    'friends can see the post'
  );

\echo
\echo when audience=personal
\echo ======================
\echo

set local "request.jwt.claim.user_id" to 1;

select
  results_eq(
    $$
    select title from posts where id = 2;
    $$,
    $$
    values('Only for myself')
    $$,
    'only the creator can see its post'
  );

set local "request.jwt.claim.user_id" to 2;

select
  is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'friends cannot see the user post'
  );

set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'non-friends cannot see the user post'
  );

\echo
\echo when audience=public
\echo =====================
\echo

set local "request.jwt.claim.user_id" to 1;

select
  results_eq(
    $$
    select title from posts where id = 3;
    $$,
    $$
    values('Hello everybody')
    $$,
    'the creator can see its own post'
  );

set local "request.jwt.claim.user_id" to 2;

select
  results_eq(
    $$
    select title from posts where id = 3;
    $$,
    $$
    values('Hello everybody')
    $$,
    'friends can see the user post'
  );

set local "request.jwt.claim.user_id" to 5;

select
  results_eq(
    $$
    select title from posts where id = 3;
    $$,
    $$
    values('Hello everybody')
    $$,
    'non-friends can see the user post'
  );

\echo
\echo when audience=whitelist
\echo =======================
\echo

set local "request.jwt.claim.user_id" to 1;

select
  results_eq(
    $$
    select title from posts where id = 4;
    $$,
    $$
    values('For some friends')
    $$,
    'the creator can see its own post'
  );

set local "request.jwt.claim.user_id" to 2;

select
  results_eq(
    $$
    select title from posts where id = 4;
    $$,
    $$
    values('For some friends')
    $$,
    'some friends can see the user post'
  );

set local "request.jwt.claim.user_id" to 3;

select
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'some friends cannot see the user post'
  );

set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'non-friends cannot see the user post'
  );

\echo
\echo when audience=blacklist
\echo =======================
\echo

set local "request.jwt.claim.user_id" to 3;

select
  results_eq(
    $$
    select title from posts where id = 5;
    $$,
    $$
    values('For all friends except')
    $$,
    'the creator can see its own post'
  );

set local "request.jwt.claim.user_id" to 4;

select
  results_eq(
    $$
    select title from posts where id = 5;
    $$,
    $$
    values('For all friends except')
    $$,
    'non blacklisted friends can see the user post'
  );

set local "request.jwt.claim.user_id" to 1;

select
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'blacklisted friends cannnot see the user post'
  );

set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'non-friends cannot see the user post'
  );

select * from finish();

do $$ begin assert num_failed() = 0; end $$;

rollback;
