begin;

select no_plan();

select 'friendships constraints' as describe;

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

select 'posts RLS' as describe;

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'When audience=friends, public cannot see the post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

select
  isnt_empty(
    $$
    select * from posts where id = 1;
    $$,
    'When audience=friends, the creator can see its post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  isnt_empty(
    $$
    select * from posts where id = 1;
    $$,
    'When audience=friends, friends can see the post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'When audience=friends, non-friends cannot see the post'
  );

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'When audience=personal, public cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

select
  isnt_empty(
    $$
    select * from posts where id = 2;
    $$,
    'When audience=personal, only the creator can see its post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'When audience=personal, friends cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'When audience=personal, non-friends cannot see the user post'
  );

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  isnt_empty(
    $$
    select * from posts where id = 3;
    $$,
    'When audience=public, public can see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

select
  isnt_empty(
    $$
    select * from posts where id = 3;
    $$,
    'When audience=public, the creator can see its own post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  isnt_empty(
    $$
    select * from posts where id = 3;
    $$,
    'When audience=public, friends can see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  isnt_empty(
    $$
    select * from posts where id = 3;
    $$,
    'When audience=public, non-friends can see the user post'
  );

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'When audience=whitelist, public cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

select
  isnt_empty(
    $$
    select * from posts where id = 4;
    $$,
    'When audience=whitelist, the creator can see its own post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  isnt_empty(
    $$
    select * from posts where id = 4;
    $$,
    'When audience=whitelist, some friends can see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

select
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'When audience=whitelist, some friends cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'When audience=whitelist, non-friends cannot see the user post'
  );

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'When audience=blacklist, public cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

select
  isnt_empty(
    $$
    select * from posts where id = 5;
    $$,
    'When audience=blacklist, the creator can see its own post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  isnt_empty(
    $$
    select * from posts where id = 5;
    $$,
    'When audience=blacklist, non blacklisted friends can see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 4;

select
  isnt_empty(
    $$
    select * from posts where id = 5;
    $$,
    'When audience=blacklist, non blacklisted friends can see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

select
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'When audience=blacklist, blacklisted friends cannnot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'When audience=blacklisted, non-friends cannot see the user post'
  );

select * from finish();
rollback;
