-- create database socnet;
begin;

drop role if exists socnet_user;
create role socnet_user;

drop role if exists socnet_anon;
create role socnet_anon;

create extension if not exists pgtap;

drop schema if exists util cascade;
create schema util;

create or replace function util.jwt_user_id()
returns int as $$
  select nullif(current_setting('request.jwt.claim.user_id', true), '')::int;
$$ language sql stable;

\ir schema.sql
\ir data.sql

commit;
