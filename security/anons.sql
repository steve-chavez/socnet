-- anons can do SELECTs on certain public rows

---------
--users--
---------

grant
  select
on users
to socnet_anon;

create policy anon_select_policy
on users
for select
to socnet_anon
using (
  true
);

-----------------
--users_details--
-----------------

grant
  select
on users_details
to socnet_anon;

create policy anon_select_policy
on users_details
for select
to socnet_anon
using (
  users_details.audience = 'public'
);

---------
--posts--
---------

grant
  select
on posts
to socnet_anon;

create policy anon_select_policy
on posts
for select
to socnet_anon
using (
  posts.audience = 'public'
);

------------
--comments--
------------

grant
  select
on comments
to socnet_anon;

create policy anon_select_policy
on comments
for select
to socnet_anon
using (
  exists (
    select 1
    from posts
    where posts.id = comments.post_id)
);
