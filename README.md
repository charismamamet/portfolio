# Portfolio
Hey, thanks for reading this readme. This portfolio folder contains both dummy project and actual project that i've done.


## 🧙 SQL Analytics rAthena

This portfolio explores in-game data using SQL, based on the rAthena database structure. It covers character ownership, item hoarding behavior, login activity, and more.

You can find the rAthena database schema on [rAthena](https://github.com/rathena/rathena).

The folders, such as [SQL Analytics rAthena], contains the queries, mock-data, and database.

The queries folder contains the .sql of each use cases.

The mock-data folder contains the mock data of the table that got used in the use-case.

Meanwhile, the database folder will contains the schema of the tables.

If you're wondering about the whole tables of rAthena database, please visit the rAthena github page.

You can also find the SQL_Use_Case.docx that contains the documentation of purpose, sql query, and the screenshot of output table.

### 📁 Use Cases on [SQL Analytics rAthena] folder

- ✅ Create table that contains item id and which char have that and which account has that. Only account that has login within last 30 days that is put on the list (item_ownership.sql)
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


## 🎸 SQL Analytics SQL Play

The [SQL Analytics SQL Play] folder contains data based on the [SQL Play Apps](https://play.google.com/store/apps/details?id=com.sql_playground).

The app itself uses the modified table name of the [chinook-database](https://github.com/lerocha/chinook-database). On the database folder, I will provide the schema of the database that this app use.

You can download the game and use my code straight at the in-game terminal to check how each code performs.

The queries for each use case is saved as .sql format which you can open with any text editor app.

I will also upload the data schema of the database that the game use.

You can still find the SQL_Use_Case_sql_play.docx that contains the documentation purpose, sql queries, and the screenshot of the output table

### 📁 Use Cases on [SQL Analytics SQL Play] folder

- ✅ table of song, artist, genre, and album (1 - song-artist-genre-album.sql)
- ✅ table of song identity and who purchased it (2 - purchased song identity and who purchased it.sql)
- ✅ Customer Distribution by Country (customer-distribution-by-country.sql) 
- ✅ Top Grossing Genres (top-grossing-genre.sql)
- ✅ Find Invoices That Contain More Than 5 Tracks (invoices-more-than-5-tracks.sql)
- ✅ Albums and the number of Tracks (album-with-tracks.sql)
- ✅ Longest and Shortest Tracks Per Genre 
- ✅ Customers Who Haven’t Made Any Purchases
- ✅ Find Repeat Customers - make purchase more than 3 separate purchases
- ✅ Top 3 Artists by Number of Tracks Sold
- ✅ Monthly Revenue Trend for the Past Year
- ✅ Best-Selling Track per Genre





