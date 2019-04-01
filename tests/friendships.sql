create or replace function tests.friendships_tests() returns setof text as $_$
begin

------------------------------------
return next
diag(
  $__$ friendships CONSTRAINTS $__$
);
------------------------------------

set local role postgres;

return next
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (1, 1, 'pending');
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check"',
    'An user cannot send a friend request to himself'
  );

return next
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (1, 5, 'pending');
    insert into friendships(source_user_id, target_user_id, status) values (5, 1, 'pending');
    $$,
    'duplicate key value violates unique constraint "unique_friend_request_idx"',
    'There can only be a friendship between two users'
  );

return next
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (1, 5, 'pending');
    insert into friendships(source_user_id, target_user_id, status) values (5, 1, 'pending');
    $$,
    'duplicate key value violates unique constraint "unique_friend_request_idx"',
    'There can only be a friendship between two users'
  );

return next
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status, blockee_id) values (5, 6, 'blocked', null);
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check1"',
    'Cannot block without adding a blockee_id'
  );

return next
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status, blockee_id) values (5, 6, 'blocked', 1);
    $$,
    'new row for relation "friendships" violates check constraint "friendships_check1"',
    'blockee_id can only be one of the users in the friendship'
  );

------------------------------------
return next
diag(
  $__$ friendships RLS $__$
);
------------------------------------

set local role socnet_anon;
reset "request.jwt.claim.user_id";

return next
  throws_ok(
    $$
    select * from friendships;
    $$,
    42501,
    'permission denied for relation friendships',
    'public cannot see any friendships'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

return next
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

return next
  throws_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (3, 6, 'pending');
    $$,
    42501,
    'new row violates row-level security policy for table "friendships"',
    'an user cannot create friendships for other users'
  );

return next
  lives_ok(
    $$
    insert into friendships(source_user_id, target_user_id, status) values (1, 6, 'pending');
    $$,
    'an user can create friendships when he is part of that friendship'
  );

------------------------------------
return next
diag(
  $__$ blocked friendships $__$
);
------------------------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

return next
  is_empty(
    $$
    select * from friendships where 3 in (source_user_id, target_user_id) or 6 in (source_user_id, target_user_id)
    $$,
    'the blockee cannot see blocked friendships'
  );

return next
  is_empty(
    $$
    update friendships set status = 'accepted' where status = 'blocked' returning *
    $$,
    'the blockee cannot modify blocked friendships'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 6;

return next
  results_eq(
    $$
    update friendships set status = 'accepted', blockee_id = null where status = 'blocked' and blockee_id = 5 returning 1
    $$,
    $$
    values(1)
    $$,
    'the blocker can update blocked status'
  );

end;
$_$ language plpgsql;
