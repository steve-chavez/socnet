begin;

select no_plan();

set local search_path = core, public;

set local role socnet_user;

\echo =======================
\echo friendships constraints
\echo =======================

set local "request.jwt.claim.user_id" to 1;

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

set local "request.jwt.claim.user_id" to 5;

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status, blockee_id) values (5, 6, 'blocked', null);
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check1"',
    'Cannot block without adding a blockee_id'
  );

select
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status, blockee_id) values (5, 6, 'blocked', 1);
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check1"',
    'blockee_id can only be one of the users in the friendship'
  );

set local "request.jwt.claim.user_id" to 1;

select
  throws_ok(
    $$
    update friendships set status = 'pending' where source_user_id = 1 and target_user_id = 2;
    $$,
    'P0001',
    'status cannot go back to pending',
    'accepted status cannot go back to pending'
  );

set local "request.jwt.claim.user_id" to 6;

select
  throws_ok(
    $$
    update friendships set status = 'pending' where source_user_id = 6 and target_user_id = 5;
    $$,
    'P0001',
    'status cannot go back to pending',
    'blocked status cannot go back to pending'
  );

\echo ===============
\echo friendships rls
\echo ===============

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
    'an user can create friendships he is part of'
  );

select
  results_eq(
    $$
    delete from friendships where source_user_id = 1 and target_user_id = 4 returning 1;
    $$,
    $$
    values(1)
    $$,
    'an user can delete friendships he is part of'
  );

select
  is_empty(
    $$
    delete from friendships where source_user_id = 2 and target_user_id = 5 returning 1;
    $$,
    'an user cannot delete friendships he is not a part of'
  );

select * from finish();

do $$ begin assert num_failed() = 0; end $$;

rollback;
