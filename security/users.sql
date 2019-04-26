-- regular users access

---------
--users--
---------

grant
  select,
  update(username)
on users
to socnet_user;

create policy select_policy
on users
for select
to socnet_user
using(
  true
);

create policy update_policy
on users
for update
to socnet_user
using (
  util.jwt_user_id() = users.id
);

-----------------
--users_details--
-----------------

grant
  select,
  insert,
  update(email, phone, audience)
on users_details
to socnet_user;

create policy own_select_policy
on users_details
for select
to socnet_user
-- user can always see its details
using(
  util.jwt_user_id() = users_details.user_id
);

create policy public_select_policy
on users_details
for select
to socnet_user
using(
  users_details.audience = 'public'
);

create policy personal_select_policy
on users_details
for select
to socnet_user
using(
  users_details.audience = 'personal'
  and
  util.jwt_user_id() = users_details.user_id
);

create policy friends_select_policy
on users_details
for select
to socnet_user
using(
  users_details.audience = 'friends'
  and
  util.jwt_user_id() in (
    select
      util.get_friend_id(users_details.user_id, f)
    from friendships f
    where
      users_details.user_id in (source_user_id, target_user_id) and
      status = 'accepted'
  )
);

create policy friends_of_friends_select_policy
on users_details
for select
to socnet_user
using(
  users_details.audience = 'friends_of_friends'
  and
  util.jwt_user_id() in (
    select util.friends_of_friends(users_details.user_id)
  )
);

create policy friends_whitelist_select_policy
on users_details
for select
to socnet_user
using(
  users_details.audience = 'friends_whitelist'
  and
  util.jwt_user_id() in (
    select
      util.get_friend_id(users_details.user_id, acc)
    from users_details_access acc
    where
      acc.user_details_id = users_details.user_id  and
      acc.access_type     = 'whitelist'
  )
);

create policy friends_blacklist_select_policy
on users_details
for select
to socnet_user
using(
  users_details.audience = 'friends_blacklist'
  and
  util.jwt_user_id() in (
    select
      util.get_friend_id(users_details.user_id, f)
    from friendships f
    where
      users_details.user_id in (source_user_id, target_user_id) and
      status = 'accepted'

    except

    select
      util.get_friend_id(users_details.user_id, acc)
    from users_details_access acc
    where
      acc.user_details_id = users_details.user_id  and
      acc.access_type     = 'blacklist'
  )
);

create policy insert_policy
on users_details
for insert
to socnet_user
with check (
  util.jwt_user_id() = users_details.user_id
);

create policy update_policy
on users_details
for update
to socnet_user
using (
  util.jwt_user_id() = users_details.user_id
);

------------------------
--users_details_access--
------------------------

grant
  select,
  insert,
  delete
on users_details_access
to socnet_user;

create policy select_policy
on users_details_access
for select
to socnet_user
using( -- can see acceses the user owns and the ones he's been assigned with
  util.jwt_user_id() in (source_user_id, target_user_id)
);

create policy insert_policy
on users_details_access
for insert
to socnet_user
with check( -- can only insert when the users_details_access belongs to the user
  util.jwt_user_id() = users_details_access.user_details_id
);

create policy delete_policy
on users_details_access
for delete
to socnet_user
using(
  util.jwt_user_id() = users_details_access.user_details_id
);

---------------
--friendships--
---------------
grant
  select,
  insert,
  update(status, since, blockee_id),
  delete
on friendships to socnet_user;

create policy select_policy
on friendships
for select
to socnet_user
using(
  true
);

create policy insert_policy
on friendships
for insert
to socnet_user
with check(
  util.jwt_user_id() in (source_user_id, target_user_id)
);

create policy update_policy
on friendships
for update
to socnet_user
using(
  util.jwt_user_id() in (source_user_id, target_user_id)
);

create policy delete_policy
on friendships
for delete
to socnet_user
using(
  util.jwt_user_id() in (source_user_id, target_user_id)
);

----------------
--posts_access--
----------------
grant
  select,
  insert,
  delete
on posts_access
to socnet_user;

create policy select_policy
on posts_access
for select
to socnet_user
using( -- can see post accesess to posts the user owns and the ones he's been assigned with
  util.jwt_user_id() in (source_user_id, target_user_id)
);

create policy insert_policy
on posts_access
for insert
to socnet_user
with check( -- can only insert when the post_id belongs to the user
  util.jwt_user_id() = posts_access.creator_id
);

create policy delete_policy
on posts_access
for delete
to socnet_user
using(
  util.jwt_user_id() = posts_access.creator_id
);

---------
--posts--
---------
grant usage on sequence posts_id_seq to socnet_user;

grant
  select,
  insert,
  update(title, body, audience),
  delete
on posts
to socnet_user;

create policy own_select_policy
on posts
for select
to socnet_user
-- creator can always see its own post
using (
  util.jwt_user_id() = posts.creator_id
);

create policy public_select_policy
on posts
for select
to socnet_user
using (
  posts.audience = 'public'
);

create policy friends_select_policy
on posts
for select
to socnet_user
using (
  posts.audience = 'friends'
  and
  util.jwt_user_id() in (
    select
      util.get_friend_id(posts.creator_id, f)
    from friendships f
    where
      posts.creator_id in (source_user_id, target_user_id) and
      status = 'accepted'
  )
);

create policy friends_of_friends_select_policy
on posts
for select
to socnet_user
using (
  posts.audience = 'friends_of_friends'
  and
  util.jwt_user_id() in (
    select util.friends_of_friends(posts.creator_id)
  )
);

create policy friends_whitelist_select_policy
on posts
for select
to socnet_user
using (
  posts.audience = 'friends_whitelist'
  and
  util.jwt_user_id() in (
    select
      util.get_friend_id(posts.creator_id, acc)
    from posts_access acc
    where
      acc.post_id     = posts.id    and
      acc.access_type = 'whitelist'
  )
);

create policy friends_blacklist_select_policy
on posts
for select
to socnet_user
using (
  posts.audience = 'friends_blacklist'
  and
  util.jwt_user_id() in (
    select
      util.get_friend_id(posts.creator_id, f)
    from friendships f
    where
      posts.creator_id in (source_user_id, target_user_id) and
      status = 'accepted'

    except

    select
      util.get_friend_id(posts.creator_id, acc)
    from posts_access acc
    where
      acc.post_id     = posts.id    and
      acc.access_type = 'blacklist'
  )
);

create policy insert_policy
on posts
for insert
to socnet_user
with check (
  util.jwt_user_id() = posts.creator_id
);

create policy update_policy
on posts
for update
to socnet_user
using (
  util.jwt_user_id() = posts.creator_id
);

create policy delete_policy
on posts
for delete
to socnet_user
using(
  util.jwt_user_id() = posts.creator_id
);

------------
--comments--
------------

grant usage on sequence comments_id_seq to socnet_user;

grant
  select,
  insert,
  update(body),
  delete
on comments
to socnet_user;

create policy select_policy
on comments
for select
to socnet_user
using (
  exists (
    select 1
    from posts
    where posts.id = comments.post_id)
);

create policy insert_policy
on comments
for insert
to socnet_user
with check (
  util.jwt_user_id() = comments.user_id
);

create policy update_policy
on comments
for update
to socnet_user
using (
  util.jwt_user_id() = comments.user_id
);

create policy delete_policy
on comments
for delete
to socnet_user
using (
  util.jwt_user_id() = comments.user_id
);
