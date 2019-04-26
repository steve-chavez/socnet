---------------
--friendships--
---------------

grant
  select
, insert
, update(status, since, blockee_id)
, delete
on friendships to socnet_user;

create policy select_policy
on friendships
for select
to socnet_user
using(
  true
);

create policy insert_policy
on friendships
for insert
to socnet_user
with check(
  util.jwt_user_id() in (source_user_id, target_user_id)
);

create policy update_policy
on friendships
for update
to socnet_user
using(
  util.jwt_user_id() in (source_user_id, target_user_id)
);

create policy delete_policy
on friendships
for delete
to socnet_user
using(
  util.jwt_user_id() in (source_user_id, target_user_id)
);
