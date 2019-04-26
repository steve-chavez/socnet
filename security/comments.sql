------------
--comments--
------------

grant usage on sequence comments_id_seq to socnet_user;

grant
  select
, insert
, update(body)
, delete
on comments
to socnet_user;

create policy select_policy
on comments
for select
to socnet_user
using (
  exists (
    select 1
    from posts
    where posts.id = comments.post_id)
);

create policy insert_policy
on comments
for insert
to socnet_user
with check (
  util.jwt_user_id() = comments.user_id
);

create policy update_policy
on comments
for update
to socnet_user
using (
  util.jwt_user_id() = comments.user_id
);

create policy delete_policy
on comments
for delete
to socnet_user
using (
  util.jwt_user_id() = comments.user_id
);
