SELECT
date(ll.time) as login_date /* need to use date(ll.time) since ll.time is formatted as datetime while i only care about the date*/,
count(distinct ll.user) as numofloginuser
FROM 
new_rathena_db.loginlog as ll
where 
log = 'login ok' /*in rAthena, char server and map server login also got count as login and it got put within the same loginlog. Meanwhile, i only care about user log in which is marked as ‘login ok’*/
group by 
login_date
order by 
login_date DESC
limit 30;
