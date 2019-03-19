begin;

do $$ begin perform no_plan(); end $$;

set search_path = core, public;

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

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (1, 5, 'pending');
    insert into friendships(source_user_id, target_user_id, status) values (5, 1, 'pending');
    $$,
    'duplicate key value violates unique constraint "unique_friend_request_idx"',
    'There can only be a friendship between two users'
  );

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status, blocker_id) values (5, 6, 'blocked', null);
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check1"',
    'Cannot block without adding a blocker_id'
  );

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status, blocker_id) values (5, 6, 'blocked', 1);
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check1"',
    'blocker_id can only be one of the users in the friendship'
  );

\echo =======================
\echo posts constraints
\echo =======================

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

\echo =========
\echo users rls
\echo =========

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from users where id in (4, 6);
    $$,
    'cannot see users that blocked you'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 4;

select
  results_eq(
    $$
    select username from users where id = 5;
    $$,
    $$
    values('yoko')
    $$,
    'can see blocked users'
  );

\echo =================
\echo users_details rls
\echo =================

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  results_eq(
    $$
    select email, phone from users_details;
    $$,
    $$
    select 'ringo@thebeatles.fake', '408-379-4348'
    $$,
    'public can only see public users details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

select
  results_eq(
    $$
    select email, phone from users_details where id = 3;
    $$,
    $$
    select 'paul@thebeatles.fake', '586-773-1545'
    $$,
    'only friends can see the users details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select email, phone from users_details where id = 3;
    $$,
    'non-friends cannot see the users details'
  );

-- set local role socnet_user;
-- set local "request.jwt.claim.user_id" to 1;

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

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  results_eq(
    $$
    select count(1) from friendships;
    $$,
    $$
    values(3::bigint)
    $$,
    'an user can only see friendships he is part of'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (3, 6, 'pending');
    $$,
    42501,
    'new row violates row-level security policy for table "friendships"',
    'an user cannot create friendships for other users'
  );

select
  lives_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (1, 6, 'pending');
    $$,
    'an user can create friendships when he is part of that friendship'
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

set local role socnet_user;
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

set local role socnet_user;
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

set local role socnet_user;
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

\echo
\echo Inserts
\echo =======
\echo

set local role socnet_user;
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

set local role socnet_user;
set local "request.jwt.claim.user_id" to 6;

select
  lives_ok(
    $$
    insert into posts(creator_id, title, body)
    values (6, 'My post', 'Just a test');
    $$,
    'Post owner can create a post in its name successfully'
  );

select * from finish();
rollback;
