# Social Network

A sample schema to be used as a base for a PostgREST tutorial on RLS.

## Requirements

- PostgreSQL >= 10, [RESTRICTIVE RLS](https://www.postgresql.org/docs/10/sql-createpolicy.html) are used.
- [pgtap](https://github.com/theory/pgtap) is used for testing.

## Install

Create and enter the db:

```bash
createdb socnet

PGOPTIONS='--search_path=core,public' \
psql socnet
```

In `psql`, create the schema and sample data with:

```postgres
\i init.sql
```

## Run the tests

For running tests do:

```postgres
\i tests.sql
```

You can also run the tests with [pg_prove](https://pgtap.org/pg_prove.html) which provides a more descriptive output that's more suitable for a CI.

```
pg_prove -v -d socnet tests/*
```

<details>
<summary>sample pg_prove output</summary>
<pre>
tests/anons.sql ..........
=====
users
=====
ok 1 - anon can see all users
=============
users_details
=============
ok 2 - anon can only see users public details
====================
users_details_access
====================
ok 3 - anon cannot see any users_details_access
========
comments
========
ok 4 - anon can see the comments of a public post
=====
posts
=====
when audience=friends
=====================
ok 5 - anon cannot see the post
when audience=friends of friends
================================
ok 6 - anon cannot see the post
when audience=public
=====================
ok 7 - anon can see the user post
when audience=whitelist
=======================
ok 8 - anon cannot see the user post
when audience=blacklist
=======================
ok 9 - anon cannot see the user post
when audience=personal
======================
ok 10 - anon cannot see the user post
============
posts_access
============
ok 11 - anon cannot see any posts_access
===========
friendships
===========
ok 12 - anon cannot see any friendships
1..12
ok
tests/comments.sql .......
============
comments RLS
============
ok 1 - an user cannot see the comments of a post he cannot see
ok 2 - an user can insert comment from himself
ok 3 - an user cannot insert a comment for other user
ok 4 - an user can update a comment he owns
ok 5 - an user cannot update other user comment
ok 6 - an user can delete his own comment
ok 7 - an user cannot delete other user comment
1..7
ok
tests/friendships.sql ....
=======================
friendships constraints
=======================
ok 1 - An user cannot send a friend request to himself
ok 2 - There can only be a friendship between two users
ok 3 - There can only be a friendship between two users
ok 4 - Cannot block without adding a blockee_id
ok 5 - blockee_id can only be one of the users in the friendship
ok 6 - accepted status cannot go back to pending
ok 7 - blocked status cannot go back to pending
===============
friendships rls
===============
ok 8 - an user cannot create friendships for other users
ok 9 - an user can create friendships he is part of
ok 10 - an user can delete friendships he is part of
ok 11 - an user cannot delete friendships he is not a part of
1..11
ok
tests/posts.sql ..........
========================
posts_access constraints
========================
ok 1 - There can only be one post whitelist entry for a friend
ok 2 - There can only be one post blacklist entry for a friend
================
posts_access rls
================
ok 3 - an user can only see posts_access which he is a part of
ok 4 - an user cannot include himself in the whitelist of a post he does not own
ok 5 - an user cannot include others on a whitelist of a post he does not own
ok 6 - post owner can include friends in the post whitelist
ok 7 - post owner cannot include non-friends in the post whitelist
ok 8 - blacklisted user cannot delete himself from the blacklist
=========
posts RLS
=========
ok 9 - An user cannot create a post in the name of another user
ok 10 - Post owner can create a post in its name successfully
ok 11 - user cannot delete posts that belong to other users
when audience=friends
=====================
ok 12 - the creator can see its post
ok 13 - friends can see the post
ok 14 - non-friends cannot see the post
when audience=friends of friends
================================
ok 15 - friends of friends can see the post
ok 16 - friends can see the post
when audience=personal
======================
ok 17 - only the creator can see its post
ok 18 - friends cannot see the user post
ok 19 - non-friends cannot see the user post
when audience=public
=====================
ok 20 - the creator can see its own post
ok 21 - friends can see the user post
ok 22 - non-friends can see the user post
when audience=whitelist
=======================
ok 23 - the creator can see its own post
ok 24 - some friends can see the user post
ok 25 - some friends cannot see the user post
ok 26 - non-friends cannot see the user post
when audience=blacklist
=======================
ok 27 - the creator can see its own post
ok 28 - non blacklisted friends can see the user post
ok 29 - blacklisted friends cannnot see the user post
ok 30 - non-friends cannot see the user post
1..30
ok
tests/users_blocked.sql ..
=========
users rls
=========
ok 1 - blockee cannot see the users that blocked him
ok 2 - blocker can see blocked users
ok 3 - blocker can see blocked users
========================
users_details_access rls
========================
ok 4 - blockee cannot see users_details_access from a blocker
=================
users_details rls
=================
ok 5 - blocked user cannot see the public users_details of a blocker
ok 6 - friends of friends which are blocked cannot see the users details
=========
posts rls
=========
ok 7 - blocked friends of friends cannot see the post
ok 8 - blocked user cannot see the public post of a blocker
================
posts_access rls
================
ok 9 - blockee cannot see posts_access from a blocker
============
comments rls
============
ok 10 - a blockee cannot see the comments of a blocker, even if the post is public
ok 11 - a blocker can see the blockee comments
===============
friendships rls
===============
ok 12 - the blockee cannot see blocked friendships
ok 13 - the blockee cannot modify blocked friendships
ok 14 - the blockee cannot delete blocked friendships
ok 15 - the blocker can update blocked status
ok 16 - the blockee_id was set to null
1..16
ok
tests/users.sql ..........
========================
users_details_access rls
========================
ok 1 - an user can only see users_details_access which he is a part of
ok 2 - an user cannot include himself in the whitelist of another user details
ok 3 - an user cannot include others on a whitelist of another user details
ok 4 - user details owner can include friends in the whitelist
ok 5 - a blacklisted user cannot remove himself from the blacklist
=========================
users_details constraints
=========================
ok 6 - Must insert a valid email
ok 7 - Must insert a valid phone
=================
users_details rls
=================
when audience=public
=====================
ok 8 - the user can see its own public details
ok 9 - friends can see the user public details
ok 10 - non-friends can see the user public details
when audience=friends
=====================
ok 11 - friends can see the users details
ok 12 - non-friends cannot see the users details
when audience=friends of friends
================================
ok 13 - friends of friends can see the users details
ok 14 - friends of friends can see the users details
when audience=friends_whitelist
===============================
ok 15 - whitelisted friend can see the users details
ok 16 - whitelisted friend can see the users details
ok 17 - non-whitelisted friend cannot see the users details
when audience=friends_blacklist
===============================
ok 18 - blacklisted friend cannot see the users details
ok 19 - non-blacklisted friend can see the users details
when audience=personal
======================
ok 20 - only the same user can see its details
ok 21 - other users cannot see the user details
1..21
ok
All tests successful.
Files=6, Tests=97,  0 wallclock secs ( 0.02 usr  0.01 sys +  0.01 cusr  0.00 csys =  0.04 CPU)
Result: PASS
</pre>
</details>

## TODO

A proper example of a VIEW with RLS is currently blocked because of a [postgres bug](https://www.postgresql.org/message-id/15708-d65cab2ce9b1717a@postgresql.org).
