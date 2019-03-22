truncate table users cascade;
copy users (id, username) from stdin delimiter ' ';
1 ringo
2 john
3 paul
4 george
5 yoko
6 brian
7 dwight
8 kevin
9 angela
10 jim
11 michael
12 pam
\.
select setval('users_id_seq', (select max(id) + 1 from users), false);

truncate table users_details cascade;
copy users_details (user_id, email, phone, audience) from stdin delimiter ' ';
1 ringo@thebeatles.fake 408-379-4348 public
3 paul@thebeatles.fake 586-773-1545 friends
4 george@thebeatles.fake 917-803-4806 friends_of_friends
7 dwight@dundermifflin.fake 954-951-8757 friends_blacklist
8 kevin@dundermifflin.fake 608-864-5863 friends_whitelist
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
2 6 accepted
8 7 accepted
7 9 accepted
10 7 accepted
7 11 accepted
7 12 accepted
8 9 accepted
10 8 accepted
11 8 accepted
8 12 accepted
\.
copy friendships (source_user_id, target_user_id, status, blocker_id) from stdin delimiter ' ';
6 5 blocked 6
3 5 blocked 3
\.

truncate table users_details_access cascade;
copy users_details_access (users_details_id, source_user_id, target_user_id, access_type) from stdin delimiter ' ';
8 8 9 whitelist
8 8 12 whitelist
7 10 7 blacklist
\.

truncate table posts cascade;
copy posts (id, creator_id, audience, title, body) from stdin delimiter '|';
1|1|friends|Excluding Yoko|Not for Yoko.
2|1|personal|Only for myself|A post for me.
3|1|public|Hello everybody|A post for everyone.
4|1|friends_whitelist|For some friends|A post for some friends.
5|3|friends_blacklist|For all friends except|A post for all except some friends.
6|6|friends_whitelist|A test for whitelist|Just a test.
\.
select setval('posts_id_seq', (select max(id) + 1 from posts), false);

truncate table posts_access cascade;
copy posts_access (post_id, creator_id, source_user_id, target_user_id, access_type) from stdin delimiter ' ';
4 1 1 2 whitelist
5 3 1 3 blacklist
\.
