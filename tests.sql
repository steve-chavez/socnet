begin;

select no_plan();

select 'friendships constraints' as describe;

select
  throws_ok(
    $$
    insert into friendships values ('1', '1', 'pending');
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check"',
    'An user cannot send a friend request to himself'
  );

select
  throws_ok(
    $$
    insert into friendships values ('1', '5', 'pending');
    insert into friendships values ('5', '1', 'pending');
    $$,
    'duplicate key value violates unique constraint "unique_friend_request_idx"',
    'There can only be a friendship between two users'
  );

select 'posts RLS' as describe;

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  isnt_empty(
    $$
    select * from posts where id = 1;
    $$,
    'Friends can see the post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'Non-friends cannot see the post'
  );

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'Public cannot see the post'
  );

select * from finish();
rollback;
