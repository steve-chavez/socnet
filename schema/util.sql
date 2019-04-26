drop schema if exists util cascade;
create schema util;

set search_path = util, core, public;

-------------------------
--utilitarian functions--
-------------------------

create or replace function jwt_user_id()
returns int as $$
  select nullif(current_setting('request.jwt.claim.user_id', true), '')::int;
$$ language sql stable;

-- given the user id we get the friend id in any of the tables that have source_user_id and target_user_id columns
create or replace function get_friend_id(user_id users.id%TYPE, x anyelement)
returns users.id%TYPE as $$
  select
    case when x.source_user_id = user_id
      then x.target_user_id
      else x.source_user_id
    end;
$$ language sql stable;

------------------------------
--security definer functions--
------------------------------

-- Actually gets friends + friends of friends
create or replace function friends_of_friends(user_id int) returns setof int as $$
with friends as (
  select
    util.get_friend_id($1, f) as friend_id
  from friendships f
  where
    $1 in (source_user_id, target_user_id) and
    status = 'accepted'
)
select
  case
    -- get the friend id
    when f0.source_user_id = $1
      then f0.target_user_id
    when f0.target_user_id = $1
      then f0.source_user_id
    -- get the friend of friend id
    when f0.source_user_id = f1.friend_id
      then f0.target_user_id
    else f0.source_user_id
  end as user_id
from friendships f0
join friends f1 on
  f1.friend_id in (f0.source_user_id, f0.target_user_id)
where
  f0.status = 'accepted'
$$ stable language sql security definer;

-- gets all blockers for an user
create or replace function blocker_ids(blocked_id int) returns setof int as $$
  select
    util.get_friend_id(f.blockee_id, f) as user_id
  from friendships f
  where
    f.blockee_id = $1
$$ stable language sql security definer;
