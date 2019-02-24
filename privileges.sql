drop role if exists socnet_user;
create role socnet_user;

drop role if exists socnet_anon;
create role socnet_anon;

grant usage on schema core to socnet_user, socnet_anon;

---------------
--friendships--
---------------
grant select, insert, update(status, since), delete on friendships to socnet_user;

alter table friendships enable row level security;
drop policy if exists friendships_policy on friendships_policy;
create policy friendships_policy on friendships to socnet_user
-- for now, an user can only see its friendships, not other users friendships.
-- Also, he can only insert friendships he's part of
using(
  util.jwt_user_id() in (source_user_id, target_user_id)
);

----------------
--posts_access--
----------------
grant select, insert, delete on posts_access to socnet_user;

alter table posts_access enable row level security;
drop policy if exists posts_access_policy on posts_access;
create policy posts_access_policy on posts_access to socnet_user
using( -- can see/insert post accesess to posts the user owns and the ones he's been assigned with
  util.jwt_user_id() in (source_user_id, target_user_id)
)
with check( -- can only insert when the post_id belongs to the user
  util.jwt_user_id() = posts_access.creator_id
);


---------
--posts--
---------
grant select, insert, update(title, body, audience), delete on posts to socnet_user;
grant usage on sequence posts_id_seq to socnet_user;
grant select on posts to socnet_anon; -- for the case of public posts

alter table posts enable row level security;
drop policy if exists posts_users_policy on posts;
create policy posts_users_policy on posts to socnet_user
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
          status = 'accepted'
      )
    when 'friends_whitelist'
      then util.jwt_user_id() in (
        select
          case when acc.source_user_id = posts.creator_id
            then acc.target_user_id
            else acc.source_user_id
          end
        from posts_access acc
        where
          acc.post_id     = posts.id    and
          acc.access_type = 'whitelist'
      )
    when 'friends_blacklist'
      then util.jwt_user_id() in (
        select
          case when f.source_user_id = posts.creator_id
            then f.target_user_id
            else f.source_user_id
          end
        from friendships f
        where
          status = 'accepted'

        except

        select
          case when acc.source_user_id = posts.creator_id
            then acc.target_user_id
            else acc.source_user_id
          end
        from posts_access acc
        where
          acc.post_id     = posts.id    and
          acc.access_type = 'blacklist'
      )
  end
)
with check (
  util.jwt_user_id() = posts.creator_id
);

drop policy if exists posts_anons_policy on posts;
create policy posts_anons_policy on posts to socnet_anon
using (
  posts.audience = 'public'
)
with check (false);
