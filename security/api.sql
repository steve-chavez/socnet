---------------
--today_posts--
---------------

alter view today_posts owner to socnet_user;

grant
  select
on api.today_posts
to socnet_api_user;
