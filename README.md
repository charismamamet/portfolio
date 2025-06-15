# Portfolio
Hey, thanks for reading this readme. This portfolio folder contains both dummy project and actual project that i've done.


## 🧙 SQL Analytics

This portfolio explores in-game data using SQL, based on the rAthena database structure. It covers character ownership, item hoarding behavior, login activity, and more.

You can find the rAthena database schema on [rAthena](https://github.com/rathena/rathena).

The folder [SQL Use Case] contains the queries, mock-data, and database.

The queries folder contains the .sql of each use cases.

The mock-data folder contains the mock data of the table that got used in the use-case.

Meanwhile, the database folder will contains the schema of the tables.

If you're wondering about the whole tables of rAthena database, please visit the rAthena github page.

You can also find the SQL_Use_Case.docx that contains the documentation of purpose, sql query, and the screenshot of output table.


### 📁 Use Cases

- ✅ Create table that contains item id and which char have that and which account is that where the account has login within last 30 days (item_ownership.sql)
- ✅ Table containing character's zeny (zeny_owner.sql)
- ✅ Table containing character's zeny and how many unique item that they have (zeny_and_item_owner.sql)
- ✅ Number of daily active users last 30 days (dau_l30d_nominal.sql)
- ✅ List of users who has login within Last 30 Days (dau_l30d_user.sql)
- ✅ List of account who has no login in for over 90 days or hasn't log in at all (stale_sign_up.sql)
- ✅ List of account who has no char or less than 2 char (lost_or_about_to_lose.sql)
- ✅ List of non-admin account who has at least 2 char (actual_player.sql)
- ✅ List of player, number of characters, and their player status flagging (playerStatus.sql)
- ✅ list of account that has more than average characters inside it (char_more_than_avg.sql)
- ✅ How many item aggregate that each users has (totalOwnedItem.sql)
- ✅ Top 3 common items (commonItem.sql)
- ✅ List of user ids that start with letter c (user_start_c.sql)
- ✅ Accounts that is suspicious of cheating cos it contains god item (cheatSus.sql)
