-- create database socnet;
begin;

create extension if not exists pgtap;

\ir schema.sql
\ir util.sql
\ir security.sql
\ir data.sql

commit;
