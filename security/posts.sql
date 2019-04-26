----------------
--posts_access--
----------------

grant
  select
, insert
, delete
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
  select
, insert
, update(title, body, audience)
, delete
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
