---------
--users--
---------

grant
  select
, update(username)
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
  select
, insert
, update(email, phone, audience)
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
  select
, insert
, delete
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
