# Social Network with RLS

First install pgtap https://github.com/theory/pgtap.

Then do:
```bash
createdb socnet
```

Then in `psql socnet` run:

```postgres
-- For creating the schema and sample data
\i init.sql
-- For running tests do:
\i tests.sql
```

You can also run the tests with [pg_prove](https://pgtap.org/pg_prove.html):
```
pg_prove -v -d socnet tests/*
```
