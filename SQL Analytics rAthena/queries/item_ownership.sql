select
	l.account_id,
    l.userid,
    l.lastlogin,
    c.char_id,
    i.id as ItemID
from
	new_rathena_db.login AS l 
left join
	new_rathena_db.char AS c on c.account_id = l.account_id
left join
	new_rathena_db.inventory AS i on i.char_id = c.char_id
WHERE
	l.lastlogin >= NOW() - interval 30 day
    AND
   	 i.id > 0
ORDER BY
	l.account_id,
    l.userid,
    c.char_id,
    ItemID
ASC;
