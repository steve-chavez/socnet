drop schema if exists api cascade;
create schema api;

set search_path = api, core, public;

create view api.today_posts as
select * from posts
where publish_date = current_date;
