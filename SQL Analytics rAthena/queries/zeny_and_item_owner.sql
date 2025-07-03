Select
c.char_id, 
c.account_id, 
c.name, 
c.zeny, 
count(distinct i.nameid) as numofitem
from new_rathena_db.char as c
left join new_rathena_db.inventory as i on i.char_id = c.char_id
group by    /* this should exist so we can get all of the char id row. Without it, we will get only one row that is the effect of count(distinct) formula */
c.char_id, 
c.account_id, 
c.name, 
c.zeny
order by c.zeny desc;
