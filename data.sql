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
copy friendships (source_user_id, target_user_id, status, id) from stdin delimiter ' ';
1 2 accepted 1
1 3 accepted 2
1 4 accepted 3
2 3 accepted 4
2 4 accepted 5
2 5 accepted 6
3 4 accepted 7
\.
select setval('friendships_id_seq', (select max(id) + 1 from friendships), false);

truncate table posts cascade;
copy posts (id, creator_id, audience, title, body) from stdin delimiter '|';
1|1|friends|Excluding Yoko|I am tired of Yoko, she always interrupts us when we record.
2|1|personal|Only for myself|A post for me.
3|1|public|Hello everybody|A post for everyone.
4|1|whitelist|For some friends|A post for some friends.
5|3|blacklist|For all friends except|A post for all except some friends.
\.
select setval('posts_id_seq', (select max(id) + 1 from posts), false);

truncate table posts_list cascade;
copy posts_list (post_id, friendship_id, list_type) from stdin delimiter ' ';
4 1 whitelist
5 2 blacklist
\.
