begin;

select no_plan();

set local search_path = api, core, public;

set local "request.jwt.claim.user_id" to 1;

\echo ===================================
\echo works with a highly privileged role
\echo ===================================

select
  results_eq(
    $$
    select count(*) from today_posts;
    $$,
    $$
    values(6::bigint);
    $$,
    'api user can see today posts'
  );

\echo ==================================================
\echo it should work with the socnet_api_user privileges
\echo ==================================================

set local role socnet_api_user;

select
  results_eq(
    $$
    select count(*) from today_posts;
    $$,
    $$
    values(6::bigint);
    $$,
    'api user can see today posts'
  );
-- Gives:
-- ERROR:  42501: permission denied for relation posts_access

-- According to the docs https://www.postgresql.org/docs/11/sql-createpolicy.html
--
-- As with normal queries and views, permission checks and policies for the tables which are referenced by a view
-- WILL USE the VIEW OWNER's RIGHTS and any POLICIES which apply to the VIEW OWNER.
--
-- However here the RIGHTS of socnet_api_user are being used.
-- Bug reported in https://www.postgresql.org/message-id/15708-d65cab2ce9b1717a@postgresql.org

select * from finish();

do $$ begin assert num_failed() = 0; end $$;

rollback;
