select 
l.account_id, 
l.userid, 
count(distinct c.char_id) as numofchar
From
new_rathena_db.login as l
left join
new_rathena_db.char as c on c.account_id = l.account_id
where
	c.char_id IS NOT NULL
	And not l.userid = 'admin'
group by
l.account_id,
l.userid
having 
numofchar >= 2
order by
numofchar DESC
;
