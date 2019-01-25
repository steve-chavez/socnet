truncate table users cascade;
copy users (id, username) from stdin delimiter ' ';
1 ringo
2 john
3 paul
4 george
5 yoko
\.

truncate table friendships cascade;
copy friendships (source_user_id, target_user_id, status) from stdin delimiter ' ';
1 2 accepted
1 3 accepted
1 4 accepted
2 3 accepted
2 4 accepted
2 5 accepted
3 4 accepted
\.

truncate table posts cascade;
copy posts (id, creator_id, title, body) from stdin delimiter '|';
1|1|Excluding Yoko|I am tired of Yoko, she always interrupts us when we record.
\.
