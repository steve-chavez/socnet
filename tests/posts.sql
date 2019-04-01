create or replace function tests.posts_tests() returns setof text as $_$
begin

------------------------------------
return next
diag(
  $__$ posts_access CONSTRAINTS $__$
);
------------------------------------

set local role postgres;

return next
  throws_ok(
    $$
    insert into posts_access(post_id, creator_id, source_user_id, target_user_id, access_type) values (5, 3, 3, 4, 'whitelist');
    insert into posts_access(post_id, creator_id, source_user_id, target_user_id, access_type) values (5, 3, 3, 4, 'whitelist');
    $$,
    'duplicate key value violates unique constraint "posts_access_pkey"',
    'There can only be one post whitelist entry for a friend'
  );

return next
  throws_ok(
    $$
    insert into posts_access(post_id, creator_id, source_user_id, target_user_id, access_type) values (5, 3, 2, 3, 'blacklist');
    insert into posts_access(post_id, creator_id, source_user_id, target_user_id, access_type) values (5, 3, 2, 3, 'blacklist');
    $$,
    'duplicate key value violates unique constraint "posts_access_pkey"',
    'There can only be one post blacklist entry for a friend'
  );

-----------------------------
return next
diag(
  $__$ posts_access RLS $__$
);
-----------------------------

set local role socnet_anon;
reset "request.jwt.claim.user_id";

return next
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

return next
  results_eq(
    $$
    select post_id from posts_access;
    $$,
    $$
    values(3)
    $$,
    'an user can only see posts_access which he is a part of'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

return next
  throws_ok(
    $$
    insert into posts_access values (6, 6, 2, 6,'whitelist');
    $$,
    42501,
    'new row violates row-level security policy for table "posts_access"',
    'an user cannot include himself in the whitelist of a post he does not own'
  );

return next
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

return next
  lives_ok(
    $$
    insert into posts_access values (6, 6, 2, 6,'whitelist');
    $$,
    'post owner can include friends in the post whitelist'
  );

return next
  throws_ok(
    $$
    insert into posts_access values (6, 6, 4, 6,'whitelist');
    $$,
    23503,
    'insert or update on table "posts_access" violates foreign key constraint "posts_access_source_user_id_fkey"',
    'post owner cannot include non-friends in the post whitelist'
  );

---------------------
return next
diag(
  $__$ posts RLS $__$
);
---------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

return next
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

return next
  lives_ok(
    $$
    insert into posts(creator_id, title, body)
    values (6, 'My post', 'Just a test');
    $$,
    'Post owner can create a post in its name successfully'
  );

---------------------------------
return next
diag(
  $__$ When audience=friends $__$
);
---------------------------------

set local role socnet_anon;
reset "request.jwt.claim.user_id";

return next
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'public cannot see the post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

return next
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

return next
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

return next
  is_empty(
    $$
    select * from posts where id = 1;
    $$,
    'non-friends cannot see the post'
  );

set local role socnet_anon;
reset "request.jwt.claim.user_id";

--------------------------------------------
return next
diag(
  $__$ When audience=friends of friends $__$
);
--------------------------------------------

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

return next
  results_eq(
    $$
    select title from posts where id = 7;
    $$,
    $$
    values('Hey!')
    $$,
    'friends of friends can see the post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 2;

return next
  results_eq(
    $$
    select title from posts where id = 7;
    $$,
    $$
    values('Hey!')
    $$,
    'friends can see the post'
  );

set local role socnet_anon;
reset "request.jwt.claim.user_id";

return next
  is_empty(
    $$
    select * from posts where id = 7;
    $$,
    'public cannot see the post'
  );

----------------------------------
return next
diag(
  $__$ When audience=personal $__$
);
----------------------------------

return next is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'public cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

return next
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

return next
  is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'friends cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

return next
  is_empty(
    $$
    select * from posts where id = 2;
    $$,
    'non-friends cannot see the user post'
  );

---------------------------------
return next
diag(
  $__$ When audience=public $__$
);
---------------------------------

set local role socnet_anon;
reset "request.jwt.claim.user_id";

return next
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

return next
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

return next
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

return next
  results_eq(
    $$
    select title from posts where id = 3;
    $$,
    $$
    values('Hello everybody')
    $$,
    'non-friends can see the user post'
  );

-----------------------------------
return next
diag(
  $__$ When audience=whitelist $__$
);
-----------------------------------

set local role socnet_anon;
reset "request.jwt.claim.user_id";

return next
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'public cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 1;

return next
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

return next
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

return next
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'some friends cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

return next
  is_empty(
    $$
    select * from posts where id = 4;
    $$,
    'non-friends cannot see the user post'
  );

-----------------------------------
return next
diag(
  $__$ When audience=blacklist $__$
);
-----------------------------------

set local role socnet_anon;
reset "request.jwt.claim.user_id";

return next
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'public cannot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 3;

return next
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

return next
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

return next
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'blacklisted friends cannnot see the user post'
  );

set local role socnet_user;
set local "request.jwt.claim.user_id" to 5;

return next
  is_empty(
    $$
    select * from posts where id = 5;
    $$,
    'non-friends cannot see the user post'
  );

end;
$_$ language plpgsql;
