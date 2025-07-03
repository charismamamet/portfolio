select 
	i.nameid,
   	count(distinct i.char_id) as numOfDistinctOwner
from new_rathena_db.inventory as i
group by 
	i.nameid
order by numOfDistinctOwner desc
limit 3
;
