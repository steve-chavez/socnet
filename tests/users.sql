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

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
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

select
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

select
  throws_ok(
    $$
    insert into users_details_access values (8, 10, 8, 'whitelist');
    $$,
    42501,
    'new row violates row-level security policy for table "users_details_access"',
    'an user cannot include himself in the whitelist of another user details'
  );

select
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

select
  lives_ok(
    $$
    insert into users_details_access values (8, 10, 8,'whitelist');
    $$,
    'user details owner can include friends in the whitelist'
  );

\echo =================
\echo users_details rls
\echo =================

\echo
\echo When audience=public
\echo =====================
\echo

set local role socnet_anon;
reset "request.jwt.claim.user_id";

select
  results_eq(
    $$
    select email, phone from users_details;
    $$,
    $$
    values('ringo@thebeatles.fake', '408-379-4348')
    $$,
    'public can only see public users details'
  );

\echo
\echo When audience=friends
\echo =====================
\echo

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

select
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

select
  is_empty(
    $$
    select email, phone from users_details where user_id = 3;
    $$,
    'non-friends cannot see the users details'
  );

\echo
\echo When audience=friends of friends
\echo ================================
\echo

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  results_eq(
    $$
    select email, phone from users_details where user_id = 4;
    $$,
    $$
    values('george@thebeatles.fake', '917-803-4806')
    $$,
    'friends of friends can see the users details'
  );

\echo
\echo When audience=friends_whitelist
\echo ===============================
\echo

set local role socnet_user;
set local "request.jwt.claim.user_id" to 9;

select
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

select
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
set local "request.jwt.claim.user_id" to 11;

select
  is_empty(
    $$
    select email, phone from users_details where user_id = 8;
    $$,
    'non-whitelisted friend cannot see the users details'
  );
