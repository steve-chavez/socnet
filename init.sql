-- create database socnet;
begin;

create extension if not exists pgtap;

drop schema if exists util cascade;
create schema util;

create or replace function util.jwt_user_id()
returns int as $$
  select nullif(current_setting('request.jwt.claim.user_id', true), '')::int;
$$ language sql stable;

\ir schema.sql
\ir functions.sql
\ir data.sql
\ir privileges.sql

commit;
