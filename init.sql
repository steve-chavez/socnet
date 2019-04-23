-- create database socnet;
begin;

create extension if not exists pgtap;
create extension if not exists citext;

\ir schema.sql
\ir util.sql
\ir security.sql
\ir data.sql

commit;
