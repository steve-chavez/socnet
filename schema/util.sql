drop schema if exists util cascade;
create schema util;

set search_path = util, core, public;

create or replace function jwt_user_id()
returns int as $$
  select nullif(current_setting('request.jwt.claim.user_id', true), '')::int;
$$ language sql stable;

-- Actually gets friends + friends of friends
create or replace function friends_of_friends(user_id int) returns setof int as $$
with friends as (
  select
    case when source_user_id = $1
      then target_user_id
      else source_user_id
    end as user_id
  from friendships
  where
    $1 in (source_user_id, target_user_id) and
    status = 'accepted')
select
  case
    when f0.source_user_id = $1
      then f0.target_user_id
    when f0.target_user_id = $1
      then f0.source_user_id
    when f0.source_user_id = f1.user_id
      then f0.target_user_id
    else f0.source_user_id
  end as user_id
from friendships f0
join friends f1 on
  f0.source_user_id = f1.user_id  or
  f0.target_user_id = f1.user_id
where
  f0.status = 'accepted'
$$ language sql security definer;

-- gets all blockers for an user
create or replace function blocker_ids(blocked_id int) returns setof int as $$
  select
    case when source_user_id = blockee_id
      then target_user_id
      else source_user_id
    end as user_id
  from friendships
  where
    $1 in (source_user_id, target_user_id) and
    status = 'blocked' and
    $1 = blockee_id
$$ language sql security definer;
