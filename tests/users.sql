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
    'friends can see the users details'
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

select
  results_eq(
    $$
    select email, phone from users_details where id = 4;
    $$,
    $$
    select 'george@thebeatles.fake', '917-803-4806'
    $$,
    'friends of friends can see the users details'
  );
