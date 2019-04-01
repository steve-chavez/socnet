create or replace function tests.users_tests() returns setof text as $_$
begin

------------------------------------
return next
diag(
  $__$ users RLS $__$
);
------------------------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

return next
  is_empty(
    $$
    select * from users where id in (3, 6);
    $$,
    'blockee cannot see the users that blocked him'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

return next
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

return next
  results_eq(
    $$
    select username from users where id = 5;
    $$,
    $$
    values('yoko')
    $$,
    'blocker can see blocked users'
  );

------------------------------------
return next
diag(
  $__$ users_details_access RLS $__$
);
------------------------------------

set local role socnet_anon;
reset "request.jwt.claim.user_id";

return next
  throws_ok(
    $$
    select * from users_details_access;
    $$,
    42501,
    'permission denied for relation users_details_access',
    'public cannot see any users_details_access'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 9;

return next
  results_eq(
    $$
    select users_details_id from users_details_access;
    $$,
    $$
    values(8)
    $$,
    'an user can only see users_details_access which he is a part of'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 10;

return next
  throws_ok(
    $$
    insert into users_details_access values (8, 10, 8, 'whitelist');
    $$,
    42501,
    'new row violates row-level security policy for table "users_details_access"',
    'an user cannot include himself in the whitelist of another user details'
  );

return next
  throws_ok(
    $$
    insert into users_details_access values (8, 11, 8, 'whitelist');
    $$,
    42501,
    'new row violates row-level security policy for table "users_details_access"',
    'an user cannot include others on a whitelist of another user details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 8;

return next
  lives_ok(
    $$
    insert into users_details_access values (8, 10, 8,'whitelist');
    $$,
    'user details owner can include friends in the whitelist'
  );

------------------------------------
return next
diag(
  $__$ users_details RLS $__$
);
------------------------------------

------------------------------------
return next
diag(
  $__$ When audience=public $__$
);
------------------------------------

set local role socnet_anon;
reset "request.jwt.claim.user_id";

return next
  results_eq(
    $$
    select email, phone from users_details;
    $$,
    $$
    values('ringo@thebeatles.fake', '408-379-4348')
    $$,
    'public can only see public users details'
  );

------------------------------------
return next
diag(
  $__$ When audience=friends $__$
);
------------------------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

return next
  results_eq(
    $$
    select email, phone from users_details where user_id = 3;
    $$,
    $$
    values('paul@thebeatles.fake', '586-773-1545')
    $$,
    'friends can see the users details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

return next
  is_empty(
    $$
    select email, phone from users_details where user_id = 3;
    $$,
    'non-friends cannot see the users details'
  );

----------------------------------------------
return next
diag(
  $__$ When audience=friends of friends $__$
);
----------------------------------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

return next
  results_eq(
    $$
    select email, phone from users_details where user_id = 4;
    $$,
    $$
    values('george@thebeatles.fake', '917-803-4806')
    $$,
    'friends of friends can see the users details'
  );

----------------------------------------------
return next
diag(
  $__$ When audience=friends_whitelist $__$
);
----------------------------------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 9;

return next
  results_eq(
    $$
    select email, phone from users_details where user_id = 8;
    $$,
    $$
    values('kevin@dundermifflin.fake', '608-864-5863')
    $$,
    'whitelisted friend can see the users details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 12;

return next
  results_eq(
    $$
    select email, phone from users_details where user_id = 8;
    $$,
    $$
    values('kevin@dundermifflin.fake', '608-864-5863')
    $$,
    'whitelisted friend can see the users details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 7;

return next
  is_empty(
    $$
    select email, phone from users_details where user_id = 8;
    $$,
    'non-whitelisted friend cannot see the users details'
  );

----------------------------------------------
return next
diag(
  $__$ When audience=friends_blacklist $__$
);
----------------------------------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 10;

return next
  is_empty(
    $$
    select email, phone from users_details where user_id = 7;
    $$,
    'blacklisted friend cannot see the users details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 8;

return next
  results_eq(
    $$
    select email, phone from users_details where user_id = 7;
    $$,
    $$
    values('dwight@dundermifflin.fake', '954-951-8757')
    $$,
    'non-blacklisted friend can see the users details'
  );

----------------------------------------------
return next
diag(
  $__$ When audience=personal $__$
);
----------------------------------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 9;

return next
  results_eq(
    $$
    select email, phone from users_details where user_id = 9;
    $$,
    $$
    values('angela@dundermifflin.fake', '408-203-3253')
    $$,
    'only the same user can see its details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 7;

return next
  is_empty(
    $$
    select email, phone from users_details where user_id = 9;
    $$,
    'other users cannot see the user details'
  );

----------------------------------------------
return next
diag(
  $__$ disabled user RLS $__$
);
----------------------------------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 11;

return next
  results_eq(
    $$
    select max(count) from(
      select count(*) from users
      union
      select count(*) from users_details
      union
      select count(*) from users_details_access
      union
      select count(*) from friendships
      union
      select count(*) from posts_access
      union
      select count(*) from posts
    ) _
    $$,
    $$
    values(0::bigint)
    $$,
    'disabled user cannot see anything'
  );

----------------------------------------------
return next
diag(
  $__$ no jwt id user rls RLS $__$
);
----------------------------------------------

reset "request.jwt.claim.user_id";

return next
  results_eq(
    $$
    select max(count) from(
      select count(*) from users
      union
      select count(*) from users_details
      union
      select count(*) from users_details_access
      union
      select count(*) from friendships
      union
      select count(*) from posts_access
      union
      select count(*) from posts
    ) _
    $$,
    $$
    values(0::bigint)
    $$,
    'When a socnet_user has no jwt id, it cannot see anything'
  );

end;
$_$ language plpgsql;
