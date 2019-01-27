begin;

do $$ begin perform no_plan(); end $$;

\echo =======================
\echo friendships constraints
\echo =======================

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values ('1', '1', 'pending');
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check"',
    'An user cannot send a friend request to himself'
  );

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values ('1', '5', 'pending');
    insert into friendships(source_user_id, target_user_id, status) values ('5', '1', 'pending');
    $$,
    'duplicate key value violates unique constraint "unique_friend_request_idx"',
    'There can only be a friendship between two users'
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

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

select
  isnt_empty(
    $$
    select * from posts where id = 1;
    $$,
    'the creator can see its post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  isnt_empty(
    $$
    select * from posts where id = 1;
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
  isnt_empty(
    $$
    select * from posts where id = 2;
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
  isnt_empty(
    $$
    select * from posts where id = 3;
    $$,
    'public can see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

select
  isnt_empty(
    $$
    select * from posts where id = 3;
    $$,
    'the creator can see its own post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  isnt_empty(
    $$
    select * from posts where id = 3;
    $$,
    'friends can see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  isnt_empty(
    $$
    select * from posts where id = 3;
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
  isnt_empty(
    $$
    select * from posts where id = 4;
    $$,
    'the creator can see its own post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  isnt_empty(
    $$
    select * from posts where id = 4;
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
  isnt_empty(
    $$
    select * from posts where id = 5;
    $$,
    'the creator can see its own post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  isnt_empty(
    $$
    select * from posts where id = 5;
    $$,
    'non blacklisted friends can see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 4;

select
  isnt_empty(
    $$
    select * from posts where id = 5;
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
