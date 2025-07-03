select
    l.account_id,
    l.userid,
    c.char_id
from
    new_rathena_db.login as l
left join
    new_rathena_db.char as c
        on c.account_id = l.account_id
left join
    new_rathena_db.inventory as i
        on i.char_id = c.char_id
where
    i.nameid = 6124
;
