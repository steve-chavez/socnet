create table users (
  id        serial  primary key
, username  text    not null
);

create type friendship_status as enum (
  'pending', 'accepted', 'blocked');

create table friendships (
  source_user_id  int                not null references users(id)
, target_user_id  int                not null references users(id)
, status          friendship_status  not null
, since           date               not null default now()

, primary key (source_user_id, target_user_id)
, check       (source_user_id <> target_user_id) -- you can't send a friend request to yourself
);

-- unique combination, once a friend request is made the target user cannot create a friend request back to the source user
create unique index unique_friend_request_idx
on friendships(
  least(source_user_id, target_user_id)
, greatest(source_user_id, target_user_id)
);
create index target_user_id_idx on friendships(target_user_id);

grant select, insert, update(status, since), delete on friendships to socnet_user;

create type post_audience as enum (
  'public', 'personal', 'friends', 'friends_whitelist', 'friends_blacklist');

create table posts (
  id          serial         primary key
, creator_id  int            not null     references users(id)
, title       text           not null
, body        text           not null
, creation    date           not null     default now()
, audience    post_audience  not null     default 'friends'
);
alter table posts enable row level security;
grant select, insert, update(title, body, audience), delete on posts to socnet_user;
grant select on posts to socnet_anon; -- for the case of public posts

create type posts_access_type as enum (
  'whitelist', 'blacklist'
);

create table posts_access (
  post_id        int                not null  references posts(id)
, source_user_id int                not null
, target_user_id int                not null
, access_type    posts_access_type  not null

, primary key (post_id, source_user_id, target_user_id, access_type)
, foreign key (source_user_id, target_user_id) references friendships(source_user_id, target_user_id)
);
grant select, insert, delete on posts_access to socnet_user;

drop policy if exists users_policy on posts;
create policy users_policy on posts to socnet_user
using (
  util.jwt_user_id() = posts.creator_id -- creator can always see its post
  or
  case audience
    when 'public'
      then true
    when 'personal'
      then util.jwt_user_id() = posts.creator_id
    when 'friends'
      then util.jwt_user_id() in (
        select
          case when f.source_user_id = posts.creator_id
            then f.target_user_id
            else f.source_user_id
          end
        from friendships f
        where
          posts.creator_id in (f.source_user_id, f.target_user_id)  and
          status           = 'accepted'
      )
    when 'friends_whitelist'
      then util.jwt_user_id() in (
        select
          case when f.source_user_id = posts.creator_id
            then f.target_user_id
            else f.source_user_id
          end
        from posts_access acc
        join friendships f on
          acc.source_user_id = f.source_user_id  and
          acc.target_user_id = f.target_user_id
        where
          acc.post_id     = posts.id    and
          acc.access_type = 'whitelist' and
          f.status        = 'accepted'
      )
    when 'friends_blacklist'
      then util.jwt_user_id() in (
        select
          case when f.source_user_id = posts.creator_id
            then f.target_user_id
            else f.source_user_id
          end
        from posts_access acc
        right join friendships f on
          acc.source_user_id = f.source_user_id  and
          acc.target_user_id = f.target_user_id  and
          acc.access_type    = 'blacklist'       and
          acc.post_id        = posts.id
        where
          acc.post_id       is  null                                  and
          f.status          =  'accepted'                             and
          posts.creator_id  in  (f.source_user_id, f.target_user_id)
      )
  end
)
with check (
  util.jwt_user_id() = creator_id
);

drop policy if exists anons_policy on posts;
create policy anons_policy on posts to socnet_anon
using (
  posts.audience = 'public'
)
with check (false);
