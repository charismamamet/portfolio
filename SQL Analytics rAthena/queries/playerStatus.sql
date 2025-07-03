select 
	l.account_id, 
	l.userid, 
	count(distinct c.char_id) as numofchar,
	case 
		when count(distinct c.char_id) > 1 then 'char collector'
        		when count(distinct c.char_id) = 0 then 'no char'
    		else 'casual player'
	end as playerStatus
From
	new_rathena_db.login as l
left join
	new_rathena_db.char as c on c.account_id = l.account_id
group by
	l.account_id,
	l.userid
order BY
	numofchar DESC
;
