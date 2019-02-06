begin;

do $$ begin perform no_plan(); end $$;

\echo =======================
\echo friendships constraints
\echo =======================

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (1, 1, 'pending');
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check"',
    'An user cannot send a friend request to himself'
  );

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (1, 5, 'pending');
    insert into friendships(source_user_id, target_user_id, status) values (5, 1, 'pending');
    $$,
    'duplicate key value violates unique constraint "unique_friend_request_idx"',
    'There can only be a friendship between two users'
  );

\echo =======================
\echo Posts constraints
\echo =======================

select
  throws_ok(
    $$
    insert into posts_access(post_id, source_user_id, target_user_id, access_type) values (5, 3, 4, 'whitelist');
    insert into posts_access(post_id, source_user_id, target_user_id, access_type) values (5, 3, 4, 'whitelist');
    $$,
    'duplicate key value violates unique constraint "posts_access_pkey"',
    'There can only be one post whitelist entry for a friend'
  );

select
  throws_ok(
    $$
    insert into posts_access(post_id, source_user_id, target_user_id, access_type) values (5, 2, 3, 'blacklist');
    insert into posts_access(post_id, source_user_id, target_user_id, access_type) values (5, 2, 3, 'blacklist');
    $$,
    'duplicate key value violates unique constraint "posts_access_pkey"',
    'There can only be one post blacklist entry for a friend'
  );

\echo =========
\echo posts RLS
\echo =========

set local role socnet_user;
reset "request.jwt.claim.user_id";

select
  results_eq(
    $$
    select id from posts;
    $$,
    $$
    values(3)
    $$,
    'When a socnet_user has no jwt id, it can only see public posts'
  );

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

set local role socnet_user;
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

set local role socnet_user;
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

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'non-friends cannot see the post'
  );

set local role socnet_anon;
reset "request.jwt.claim.user_id";

\echo
\echo When audience=personal
\echo ======================
\echo

select is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'public cannot see the user post'
  );

set local role socnet_user;
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

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'friends cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'non-friends cannot see the user post'
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

set local role socnet_user;
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

set local role socnet_user;
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

set local role socnet_user;
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

set local role socnet_user;
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

set local role socnet_user;
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

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

select
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'some friends cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'non-friends cannot see the user post'
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

set local role socnet_user;
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

set local role socnet_user;
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

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

select
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'blacklisted friends cannnot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'non-friends cannot see the user post'
  );

select * from finish();
rollback;
