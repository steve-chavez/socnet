drop schema if exists core cascade;
create schema core;
set search_path = core, public;

create table users (
  id        serial  primary key
, username  text    not null
, disabled  bool    not null default 'false'
);

create type audience as enum (
  'personal',
  'friends_whitelist',
  'friends_blacklist',
  'friends',
  'friends_of_friends',
  'public'
);

create table users_details (
  user_id   int       primary key references users(id)
, email     text      check ( email ~* '^.+@.+\..+$' )
, phone     text      not null
, audience  audience  not null  default 'friends'
);

create type friendship_status as enum (
  'pending', 'accepted', 'blocked'
);

create table friendships (
  source_user_id  int                not null references users(id)
, target_user_id  int                not null references users(id)
, status          friendship_status  not null
, blockee_id      int                null     references users(id)
, since           date               not null default now()

, primary key (source_user_id, target_user_id)
, check       (source_user_id <> target_user_id) -- you can't send a friend request to yourself
, check       (not (status = 'blocked' and (blockee_id is null or blockee_id not in (source_user_id, target_user_id)))) -- don't let a block happen when a blockee_id is null or the blockee_id doesn't belong to the friendship
);

-- unique combination, once a friend request is made the target user cannot create a friend request back to the source user
create unique index unique_friend_request_idx
on friendships(
  least(source_user_id, target_user_id)
, greatest(source_user_id, target_user_id)
);
create index target_user_id_idx on friendships(target_user_id);

create type access_type as enum (
  'whitelist', 'blacklist'
);

create table users_details_access (
  users_details_id  int          not null  references users_details(user_id)
, source_user_id    int          not null
, target_user_id    int          not null
, access_type       access_type  not null

, primary key            (users_details_id, source_user_id, target_user_id, access_type)
, foreign key            (source_user_id, target_user_id)
  references friendships (source_user_id, target_user_id)
);

create table posts (
  id            serial    primary key
, creator_id    int       not null     references users(id)
, title         text      not null
, body          text      not null
, publish_date  date      not null     default now()
, audience      audience  not null     default 'friends'
);

create table posts_access (
  post_id         int          not null  references posts(id)
, creator_id      int          not null  references users(id)
, source_user_id  int          not null
, target_user_id  int          not null
, access_type     access_type  not null

, primary key            (post_id, source_user_id, target_user_id, access_type)
, foreign key            (source_user_id, target_user_id)
  references friendships (source_user_id, target_user_id)
);
