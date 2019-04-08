begin;
select no_plan();

set search_path = core, public;

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

\echo =========================
\echo users_details constraints
\echo =========================

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

select
  throws_ok(
    $$
    insert into users_details values (2, 'johnthebeatles.fake', null);
    $$,
    'new row for relation "users_details" violates check constraint "users_details_email_check"',
    'Must insert a valid email'
  );

select
  throws_ok(
    $$
    insert into users_details values (2, 'john@thebeatles.fake', 'ABC-292-0725');
    $$,
    'new row for relation "users_details" violates check constraint "users_details_phone_check"',
    'Must insert a valid phone'
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
    select email from users_details;
    $$,
    $$
    values
      ('ringo@thebeatles.fake'),
      ('brian@thebeatles.fake')
    $$,
    'anon can only see public users details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

select
  is_empty(
    $$
    select email, phone from users_details where user_id = 6;
    $$,
    'blocked user cannot see the public users_details of a blocker'
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
set local "request.jwt.claim.user_id" to 7;

select
  is_empty(
    $$
    select email, phone from users_details where user_id = 8;
    $$,
    'non-whitelisted friend cannot see the users details'
  );

\echo
\echo When audience=friends_blacklist
\echo ===============================
\echo

set local role socnet_user;
set local "request.jwt.claim.user_id" to 10;

select
  is_empty(
    $$
    select email, phone from users_details where user_id = 7;
    $$,
    'blacklisted friend cannot see the users details'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 8;

select
  results_eq(
    $$
    select email, phone from users_details where user_id = 7;
    $$,
    $$
    values('dwight@dundermifflin.fake', '954-951-8757')
    $$,
    'non-blacklisted friend can see the users details'
  );

\echo
\echo When audience=personal
\echo ======================
\echo

set local role socnet_user;
set local "request.jwt.claim.user_id" to 9;

select
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

select
  is_empty(
    $$
    select email, phone from users_details where user_id = 9;
    $$,
    'other users cannot see the user details'
  );

\echo =================
\echo disabled user rls
\echo =================

set local role socnet_user;
set local "request.jwt.claim.user_id" to 11;

select
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

\echo ==================
\echo no jwt id user rls
\echo ==================

reset "request.jwt.claim.user_id";

select
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

select * from finish();

do $$ begin assert num_failed() = 0; end $$;

rollback;
