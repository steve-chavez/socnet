create table users (
  id        serial  primary key
, username  text    not null
-- , email     text    not null
-- , password  text    not null
);

grant insert on users to socnet_anon;

create type friendship_status as enum ('pending', 'accepted', 'blocked');

create table friendships (
  source_user_id  int                not null references users(id)
, target_user_id  int                not null references users(id)
, status          friendship_status  not null
, since           date               not null default now()

, check (source_user_id <> target_user_id) -- you can't send a friend request to yourself
);
-- unique combination, once a friend request is made the target user cannot create a friend request back to the source user
create unique index unique_friend_request_idx
on friendships(
  least(source_user_id, target_user_id),
  greatest(source_user_id, target_user_id)
);

grant select, insert, update(status, since), delete on friendships to socnet_user;

create table posts (
  id          serial  primary key
, creator_id  int     not null references users(id)
, title       text    not null
, body        text    not null
, creation    date    not null default now()
);

grant all on posts to socnet_user;
grant select on posts to socnet_anon; -- for the case of public posts

alter table posts enable row level security;
-- only friends can see posts
drop policy if exists posts_access_policy on posts;
create policy posts_access_policy on posts to socnet_user
using (
  util.jwt_user_id() = creator_id
  or
  util.jwt_user_id() in (
    select
      case when source_user_id = creator_id
        then target_user_id
        else source_user_id
      end
    from friendships
    where
      status = 'accepted'  and
      source_user_id    = creator_id  or
      target_user_id    = creator_id)
)
with check (
  util.jwt_user_id() = creator_id
);
