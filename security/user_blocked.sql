---------
--users--
---------

create policy blocked_select_policy
on users
as restrictive
for select
to socnet_user
using(
  users.id not in (
    select util.blocker_ids(util.jwt_user_id())
  )
);

-----------------
--users_details--
-----------------

create policy blocked_select_policy
on users_details
as restrictive
for select
to socnet_user
using(
  case audience
    when 'public'
      then users_details.user_id not in (
        select util.blocker_ids(util.jwt_user_id())
      )
    else true
  end
);

---------------
--friendships--
---------------

create policy blocked_select_policy
on friendships
as restrictive
for select
to socnet_user
-- can see all friendships except the blocked ones
using(
  case status
    when 'blocked'
      then blockee_id is null or util.jwt_user_id() <> blockee_id
    else true
  end
);

---------
--posts--
---------

create policy blocked_select_policy
on posts
as restrictive
for select
to socnet_user
using(
  case audience
    when 'public'
      then posts.creator_id not in (
        select util.blocker_ids(util.jwt_user_id())
      )
    else true
  end
);

------------
--comments--
------------

create policy blocked_select_policy
on comments
as restrictive
for select
to socnet_user
using (
  comments.user_id not in (
    select util.blocker_ids(util.jwt_user_id())
  )
);
