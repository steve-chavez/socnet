truncate table users cascade;
copy users (id, username) from stdin delimiter ' ';
1 ringo
2 john
3 paul
4 george
5 yoko
\.
select setval('users_id_seq', (select max(id) + 1 from users), false);

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
copy posts (id, creator_id, audience, title, body) from stdin delimiter '|';
1|1|friends|Excluding Yoko|I am tired of Yoko, she always interrupts us when we record.
2|1|personal|Only for myself|A post for me.
3|1|public|Hello everybody|A post for everyone.
4|1|friends_whitelist|For some friends|A post for some friends.
5|3|friends_blacklist|For all friends except|A post for all except some friends.
\.
select setval('posts_id_seq', (select max(id) + 1 from posts), false);

truncate table posts_access cascade;
copy posts_access (post_id, source_user_id, target_user_id, access_type) from stdin delimiter ' ';
4 1 2 whitelist
5 1 3 blacklist
\.
