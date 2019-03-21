drop schema if exists core cascade;
create schema core;
set search_path = core, public;

create table users (
  id        serial  primary key
, username  text    not null
);

create type details_audience as enum (
  'public', 'friends', 'friends_of_friends',
  'friends_whitelist', 'friends_blacklist'
);

create table users_details (
  id        int               primary key references users(id)
, email     text              check ( email ~* '^.+@.+\..+$' )
, phone     text              not null
, audience  details_audience  not null
);

create type friendship_status as enum (
  'pending', 'accepted', 'blocked'
);

create table friendships (
  source_user_id  int                not null references users(id)
, target_user_id  int                not null references users(id)
, status          friendship_status  not null
, blocker_id      int                null     references users(id)
, since           date               not null default now()

, primary key (source_user_id, target_user_id)
, check       (source_user_id <> target_user_id) -- you can't send a friend request to yourself
, check       (not (status = 'blocked' and (blocker_id is null or blocker_id not in (source_user_id, target_user_id)))) -- don't let a block happen when a blocker_id is null or the blocker_id doesn't belong to the friendship
);

-- unique combination, once a friend request is made the target user cannot create a friend request back to the source user
create unique index unique_friend_request_idx
on friendships(
  least(source_user_id, target_user_id)
, greatest(source_user_id, target_user_id)
);
create index target_user_id_idx on friendships(target_user_id);

create type access_list_type as enum (
  'whitelist', 'blacklist'
);

create table users_details_access (
  users_details_id  int                not null  references users_details(id)
, source_user_id    int                not null
, target_user_id    int                not null
, access_type       access_list_type   not null

, primary key            (users_details_id, source_user_id, target_user_id, access_type)
, foreign key            (source_user_id, target_user_id)
  references friendships (source_user_id, target_user_id)
);

create type post_audience as enum (
  'public', 'personal', 'friends',
  'friends_whitelist', 'friends_blacklist'
);

create table posts (
  id            serial         primary key
, creator_id    int            not null     references users(id)
, title         text           not null
, body          text           not null
, publish_date  date           not null     default now()
, audience      post_audience  not null     default 'friends'
);

create table posts_access (
  post_id         int                not null  references posts(id)
, creator_id      int                not null  references users(id)
, source_user_id  int                not null
, target_user_id  int                not null
, access_type     access_list_type   not null

, primary key            (post_id, source_user_id, target_user_id, access_type)
, foreign key            (source_user_id, target_user_id)
  references friendships (source_user_id, target_user_id)
);
