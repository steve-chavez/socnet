-- create database socnet;
-- Follow this guide:
-- you can see all friends details; some friends of friends details; and anyone else visibility is determined by privacy settings

create role socnet_user;
create role socnet_anon;

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

alter table posts enable row level security;
-- only friends can see posts
create policy posts_access_policy on posts to socnet_user
using (
  current_setting('request.jwt.claim.user_id', true)::int in (
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
  or
  current_setting('request.jwt.claim.user_id', true)::int = creator_id
)
with check (
  current_setting('request.jwt.claim.user_id', true)::int = creator_id
);

COPY users (username) FROM STDIN;
ringo
john
paul
george
yoko
\.

COPY friendships (source_user_id, target_user_id, status) FROM STDIN delimiter ' ';
1 2 accepted
1 3 accepted
1 4 accepted
2 3 accepted
2 4 accepted
3 4 accepted
\.

COPY posts (creator_id, title, body) FROM STDIN delimiter '|';
1|Excluding Yoko|I am tired of Yoko, she always interrupts us when we record.
\.

-- get all friends ids
select
      case when source_user_id = 1
        then target_user_id
        else source_user_id
      end
    from friendships
    where
      status = 'accepted'  and
      source_user_id    = 1  or
      target_user_id    = 1;

-- rls using
select current_setting('request.jwt.claim.user_id', true)::int in (
	select
		case when source_user_id = 1
			then target_user_id
			else source_user_id
		end
	from friendships
	where
		status = 'accepted'  and
		source_user_id    = 1  or
		target_user_id    = 1);

-- can see post himself
begin;
set local role socnet_user;
set "request.jwt.claim.user_id" to 1;
select * from posts;
rollback;

-- A friend case
begin;
set local role socnet_user;
set "request.jwt.claim.user_id" to 2;
select * from posts;
rollback;

-- Not a friend case
begin;
set local role socnet_user;
set "request.jwt.claim.user_id" to 5;
select * from posts;
rollback;

-- Anonymous case
begin;
set local role socnet_user;
select * from posts;
rollback;
